#!/usr/bin/env python3
import glob
import os
import argparse
import subprocess
import plistlib
import shutil
import sys
import tempfile
import hashlib


def main():
    parser = argparse.ArgumentParser(
            description="Build and check the API compatibility.")

    subparsers = parser.add_subparsers(dest='command')

    dumpSDKParser = subparsers.add_parser("dump", description="""
    Dump the SDK to a JSON file.
    This command supports a few modes:
        1) Dumping from a zip archive of the SDK. Zip archive must contain XCFramework along with the dependencies.
        2) Dumping from a XCFramework. The XCFramework dependencies must be in the same root folder.
        3) Dumping from a folder of swiftmodule files. This is useful for dumping from DerivedData. In that case you must specify the triplet target with --triplet-target.
    In most cases you also have to specify the module name with --module.
    """, formatter_class=argparse.RawTextHelpFormatter, help="Generate JSON API report.")
    dumpSDKParser.add_argument("sdk_path", metavar="sdk-path", type=os.path.abspath, help="Path to the Maps SDK release zip archive.")
    dumpSDKParser.add_argument("--module", help="Name of the module to dump.")
    dumpSDKParser.add_argument("--triplet-target", help="Clang target triplet like 'arm64-apple-ios11.0'")
    dumpSDKParser.add_argument("--abi", default=False, action=argparse.BooleanOptionalAction, help="Generate ABI report.")
    dumpSDKParser.add_argument("-o", "--output-path", type=os.path.abspath, help="Path to the output JSON API report. Default to <sdk-name>.API.json")

    checkAPIParser = subparsers.add_parser("check-api", help="Check for API breakage.")
    checkAPIParser.add_argument("base_dump", metavar="base-dump-path", type=os.path.abspath, help="Path to the baseline (old) SDK API JSON dump.")
    checkAPIParser.add_argument("latest_dump", metavar="latest-dump-path", type=os.path.abspath, help="Path to the latest (new) SDK API JSON dump.")
    checkAPIParser.add_argument("--breakage-allowlist-path", type=os.path.abspath, help="Path to the file containing the list of allowed API breakages.")
    checkAPIParser.add_argument("--report-path", default="api-check-report.txt", type=os.path.abspath, help="Path to the API check report.")
    checkAPIParser.add_argument("--comment-pr", default=False, action=argparse.BooleanOptionalAction, help="Leave a comment on the PR with the API check report.")

    args = parser.parse_args()

    if args.command == "dump":
        dump_sdk(args.sdk_path, args.output_path, args.abi, args.module, args.triplet_target)
    elif args.command == "check-api":
        check_api_breaking_changes(args.base_dump, args.latest_dump, args.breakage_allowlist_path, args.report_path, args.comment_pr)

def dump_sdk(sdk_path:str, output_path:str, abi:bool, module_name:str, triplet_target: str = None):
    tempDir = tempfile.mkdtemp(prefix="API-check-")
    print(tempDir)

    def dittoSDK(sdk_path, destination):
        if os.path.splitext(sdk_path)[1] == ".zip":
            # If the SDK is a zip archive, unzip it first.
            # Then copy the contents of artifacts/ folder to the destination.
            # to align structure with other SDKs.
            shutil.unpack_archive(sdk_path, destination)
            if os.path.exists(os.path.join(destination, "artifacts")):
                artifacts_path = os.path.join(destination, "artifacts/")
                for f in os.listdir(artifacts_path):
                    shutil.move(os.path.join(artifacts_path, f), destination)
                shutil.rmtree(artifacts_path)
            return destination
        elif os.path.splitext(sdk_path)[1] == ".xcframework":
            return os.path.dirname(sdk_path)
        elif len(glob.glob1(sdk_path,"*.swiftmodule")) > 0:
            # Support raw folder of swiftmodule files like the one in DerivedData.
            return sdk_path
        else:
            raise Exception("SDK path must contain a zip archive, XCFrameworks or a folder of swiftmodule files")

    def detect_module_name(sdk_path: str, frameworks_root: str) -> str:
        if os.path.splitext(sdk_path)[1] == ".zip":
            modules = [f for f in os.listdir(frameworks_root) if f.endswith(".xcframework")]
            if len(modules) != 1:
                raise Exception(f"Could not detect module name from {sdk_path}")
            else:
                return modules[0].split(".")[0]
        elif os.path.splitext(sdk_path)[1] == ".xcframework":
            return os.path.splitext(os.path.basename(sdk_path))[0]
        else:
            raise Exception("Cannot detect module name from SDK path. Please specify the module name with --module")

    frameworks_root = dittoSDK(sdk_path, tempDir)
    if module_name is None:
        print("Detecting module name...")
        module_name = detect_module_name(sdk_path, frameworks_root)
        print(f"Module name: {module_name}")

    xcframework_path = os.path.join(frameworks_root, f"{module_name}.xcframework")
    digester = APIDigester()
    if output_path is None:
        suffix = "ABI" if abi else "API"
        output_path = os.path.abspath(f"{module_name}.{suffix}.json")

    if os.path.exists(xcframework_path):
        current_xcframework = XCFramework(xcframework_path)

        digester.dump_sdk_xcframework(current_xcframework, frameworks_root, output_path, abi)
    else:
        # We are in the DerivedData folder.
        if triplet_target is None:
            raise Exception("Please specify the triplet target with --triplet-target. That option is required when dumping from modules folder.")
        digester.dump_sdk(frameworks_root, module_name, triplet_target, output_path, abi)

def check_api_breaking_changes(baseline_dump_path:str, latest_dump_path:str, breakage_allow_list_path:str, report_path:str, should_comment_pr:bool):
    tool = APIDigester()

    report = tool.compare(baseline_dump_path, latest_dump_path, report_path, breakage_allow_list_path)

    if should_comment_pr:
        add_comment_to_pr(report)

    if not report.is_good:
        print(f"""
======================================
ERROR: API breakage detected in {os.path.basename(latest_dump_path)}
======================================
{open(report_path, "r").read()}
        """, file=sys.stderr)
        exit(1)


def add_comment_to_pr(report: 'APIDigester.BreakageReport'):
    print("Commenting on PR")
    if report.is_good:
        comment = f"""
**API compatibility report:** ✅
        """
    else:
        comment = f"""
## API compatibility report: ❌
"""
        for category in report.breakage:
            comment += f"#### {category}\n"
            for breakage in report.breakage[category]:
                comment += f"* `{breakage}`\n"


    open("comment.txt", "w").write(comment)
    proc = subprocess.run(["gh", "pr", "comment", "--edit-last", "--body-file", "comment.txt"])
    if proc.returncode != 0 and not report.is_good:
        subprocess.run(["gh", "pr", "comment", "--body-file", "comment.txt"])

    os.remove("comment.txt")

class APIDigester:

    def compare(self, baseline_path, current_path, output_path, breakage_allow_list_path:str = None):
        arguments = ["xcrun", "--sdk", "iphoneos", "swift-api-digester",
                    "-diagnose-sdk",
                    "-o", output_path,
                    "-input-paths", baseline_path,
                    "-input-paths", current_path,
                    "-v"
                    ]

        if breakage_allow_list_path:
            arguments.append("-breakage-allowlist-path")
            arguments.append(breakage_allow_list_path)

        proc = subprocess.run(arguments, capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stderr)
            raise Exception("swift-api-digester failed")

        return APIDigester.BreakageReport(output_path)

    def dump_sdk(self, modules_path: str, module_name: str, triplet_target: str, output_path: str, abi: bool):
        arguments = ["xcrun", "--sdk", "iphoneos", "swift-api-digester",
                    "-dump-sdk",
                    "-I", modules_path,
                    "-module", module_name,
                    "-o", output_path,
                    "-avoid-tool-args", "-avoid-location",
                    "-target", triplet_target,
                    "-v"
                    ]

        if abi:
            arguments.append("-abi")

        proc = subprocess.run(arguments, capture_output=True, text=True, cwd=modules_path)
        if proc.returncode != 0:
            print(proc.stderr)
            raise Exception("swift-api-digester failed")

    def dump_sdk_xcframework(self, xcframework: 'XCFramework', dependencies_path, output_path, abi: bool = False):
        module = xcframework.iOSDeviceModule()
        arguments = ["xcrun", "--sdk", "iphoneos", "swift-api-digester",
                    "-dump-sdk",
                    "-o", output_path,
                    "-abort-on-module-fail",
                    "-v",
                    "-avoid-tool-args", "-avoid-location",
                    ]

        if abi:
            arguments.append("-abi")

        def append_dependencies(arguments: list):
            deps = module.list_dependencies()
            deps_names = map(lambda dep: os.path.basename(dep), deps)
            xcDeps = list(map(lambda dep: XCFramework(os.path.join(dependencies_path, dep)), [d for d in os.listdir(dependencies_path) if os.path.isdir(os.path.join(dependencies_path, d)) and d.endswith('.xcframework')]))

            for dependency in deps:
                dependency_name = os.path.basename(dependency)
                for xcDep in xcDeps:
                    if xcDep.name == dependency_name:
                        arguments.append("-iframework")
                        arguments.append(os.path.dirname(xcDep.iOSDeviceModule().path))
                        break

        def append_module(arguments: list):
            module = xcframework.iOSDeviceModule()
            arguments.extend([
                "-module", xcframework.name,
                "-target", module.triplet_target(),
                "-iframework", os.path.dirname(module.path),
                ])

        append_dependencies(arguments)
        append_module(arguments)

        proc = subprocess.run(arguments, capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stderr)
            raise Exception("swift-api-digester failed")

    class BreakageReport:
        def __init__(self, path):
            self.path = path
            self.breakage = {}
            self.__parseReport()
            self.hashsum = self.__hashsum()
            self.is_good = self.hashsum == self.__empty_report_hashsum()

        def __parseReport(self):
            for line in open(self.path).readlines():
                if len(line.strip()) == 0:
                    category = None
                    continue
                if line.startswith("/* "):
                    category = line[3:-4]
                elif category:
                    self.breakage[category] = self.breakage.get(category, []) + [line]

        def __hashsum(self):
            sha_hash = hashlib.sha1()
            with open(self.path, "rb") as f:
                # Read and update hash string value in blocks of 4K
                for byte_block in iter(lambda: f.read(4096),b""):
                    sha_hash.update(byte_block)
                return sha_hash.hexdigest()

        def __empty_report_hashsum(self):
            # Represents a sha1 hashsum of an empty report (including section names).
            return "afd2a1b542b33273920d65821deddc653063c700"

class Executable:
    def __init__(self, path):
        self.path = path

    def parse_load_commands(self):
        otool_proc = subprocess.run(["otool", "-l", self.path], capture_output=True, text=True)
        if otool_proc.returncode != 0:
            print(otool_proc.stderr)
            raise Exception(f"Failed to run otool -l {self.path}")

        load_commands = []
        command_buffer = {}
        for line in otool_proc.stdout.splitlines()[1:]:
            line = line.strip()
            if len(line) == 0:
                continue

            if line.startswith("Load command"):
                if command_buffer and len(command_buffer) > 0:
                    load_commands.append(command_buffer)
                command_buffer = {}
            elif line.startswith("Section"):
                if command_buffer and len(command_buffer) > 0:
                    load_commands.append(command_buffer)
                command_buffer = None
            elif command_buffer is not None:
                key = line.split(" ")[0]
                value = " ".join(line.split(" ")[1:])
                command_buffer[key] = value

        if command_buffer is not None and len(command_buffer) > 0:
            load_commands.append(command_buffer)

        return load_commands

    def list_all_dependencies(self):
        dynamic_dependencies = subprocess.run(["xcrun", "otool", "-L", self.path], capture_output=True, text=True).stdout.strip().split("\n\t")
        return list(map(lambda x: x.split()[0], dynamic_dependencies[1:]))

class SDKModule:
    def __init__(self, root, library: 'XCFramework.Library'):
        self.library = library
        self.path = os.path.join(root, library.libraryIdentifier(), library.path())
        self.__parse_info_plist()

    def __parse_info_plist(self):
        with open(os.path.join(self.path, "Info.plist"), "rb") as f:
            self.plist = plistlib.load(f)

    def minimum_os_version(self):
        return self.plist["MinimumOSVersion"]

    def triplet_target(self):
        # Returns the target triple for the module in format 'arm64-apple-ios11.0'
        return f"{self.library.supported_architectures()[0]}-apple-{self.library.supported_platform()}{self.minimum_os_version()}"

    def executable_path(self):
        return self.plist["CFBundleExecutable"]

    def executable(self) -> Executable:
        path = os.path.join(self.path, self.executable_path())
        return Executable(path)

    def __repr__(self):
        return f"SDKModule({self.path, self.plist})"

    def list_all_dependencies(self):
        dynamic_dependencies = subprocess.run(["xcrun", "otool", "-L", self.executable()], capture_output=True, text=True).stdout.strip().split("\n\t")
        return list(map(lambda x: x.split()[0], dynamic_dependencies[1:]))

    def list_dependencies(self):
        module_path = os.path.join(self.library.library["LibraryPath"], self.executable_path())
        def filter_system_dependencies(dependency):
            return not dependency.startswith("/usr/lib") \
                and not dependency.startswith("/System") \
                    and not dependency.endswith(".dylib") \
                        and not dependency.endswith(module_path)

        return list(filter(filter_system_dependencies, self.executable().list_all_dependencies()))

class XCFramework:
    class Library:
        def __init__(self, library, root_path):
            self.library = library
            self.root_path = root_path

        def __repr__(self):
            return f"XCFramework.Library({self.library})"

        def path(self) -> str:
            return self.library["LibraryPath"]

        def libraryIdentifier(self) -> str:
            return self.library["LibraryIdentifier"]

        def supported_platform(self) -> str:
            return self.library["SupportedPlatform"]

        def supported_platform_variant(self) -> str:
            return self.library["SupportedPlatformVariant"]

        def supported_architectures(self) -> list:
            return self.library["SupportedArchitectures"]

        def is_simulator(self):
            return self.supported_platform_variant() == "simulator"

        def is_device(self):
            return not "SupportedPlatformVariant" in self.library

        def is_ios(self):
            return self.supported_platform() == "ios"

        def is_macos(self):
            return self.supported_platform() == "macos"

    def __init__(self, path):
        self.path = os.path.abspath(path)

        if not os.path.isdir(self.path) and self.path.endswith(".xcframework"):
            raise Exception(f"{self.path} is not a valid XCFramework")

        self.name = os.path.basename(self.path).split(".")[0]
        self.libraries = self.__parse_libraries()

    def __parse_libraries(self):
        with open(os.path.join(self.path, "Info.plist")) as f:
            plist = plistlib.loads(f.read().encode("utf-8"))
            return list(map(lambda x: XCFramework.Library(x, self.path), plist["AvailableLibraries"]))

    def iOSDeviceModule(self):
        deviceLibrary = list(filter(lambda x: x.is_ios() and x.is_device(), self.libraries))[0]
        # return SDKModule(os.path.join(self.path, deviceLibrary.libraryIdentifier(), deviceLibrary.path()))
        return SDKModule(self.path, deviceLibrary)

    def __repr__(self):
        return f"XCFramework({self.path})"

if __name__ == "__main__":
    main()
