if [ ! -d "scipts/Scipio" ]; then
    git clone https://github.com/giginet/Scipio.git scipts/Scipio
fi
cd scipts/Scipio
git checkout "0.21.0"
swift build -c release

swift run -c release scipio create ../.. -f \
    --platforms iOS  \
    --only-use-versions-from-resolved-file \
    --enable-library-evolution \
    --support-simulators \
    --embed-debug-symbols \
    --verbose