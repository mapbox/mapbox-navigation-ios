import Foundation

/**
 * State transitions of an offline region.
 *
 *                  download()
 *                      │
 *                      │
 *                   ┌──▼──────┐
 *              ┌────▶ Pending ├─────────────delete()────┐
 *              │    └───────▲─┘                         │
 *              │      │  │  │                           │
 *          download() │  │  └───download()──┐           │
 *              │      │  │                  │           │
 *              │      │  │           ┌──────┴─────┐     │
 *              │      │  └─cancel()──▶ Incomplete ├──┐  │
 *              │      │              └──────▲─────┘  │  │
 *      ┌───────┴─┐  (scheduled)             │        │  │
 *      │ Errored │    │                     │        │  │
 *      └─▲──┬──▲─┘    │    ┌────cancel()────┘        │  │
 *        │  │  │      │    │                   delete() │
 *        │  │  │  ┌───▼─────────┐                    │  │
 *        │  │  └──│ Downloading │───delete()──────┐  │  │
 *        │  │     └─────────────┘                 │  │  │
 *        │  │            │                        │  │  │
 *        │  │       (completes)                 ┌ ▼ ─▼─ ▼ ┐
 *        │  └────────────│───────────delete()───▶ Deleted
 *        │               │                      └ ─▲─ ─▲─ ┘
 *        │         ┌─────▼─────┐                   │   │
 *     (failed)─────│ Verifying │─────delete()──────┘   │
 *                  └───────────┘                       │
 *                        │                         (succeeds)
 *                   (successful)                       │
 *                        │                             │
 *                  ┌─────▼─────┐                  ┌────┴─────┐
 *                  │ Available ├───────delete()───▶ Deleting │
 *                  └─────▲─────┘                  └────┬─────┘
 *                        │                             │
 *                        └─────────download()──────────┘
 */
public enum OfflineRegionStatus: Equatable {
    /**
     This offline pack is marked for downloading, but it has not yet begun.
     Check the `downloadedBytes` field against the pack's `totalBytes` to compute progress.
     The file on disk is unusable.
     */
    case pending
    /**
     The download is in progress.
     Check the `downloadedBytes` field against the pack's `totalBytes` to compute progress.
     The file on disk is unusable.
     */
    case downloading
    /**
     The offline pack is complete and the file on disk is usable.
     */
    case available
    /**
     The download is incomplete, and not scheduled to be downloaded.
     Check the `downloadedBytes` field against the pack metadata's `totalBytes` to compute progress.
     The file on disk is unusable.
     */
    case incomplete
    /**
     The download is complete, but not yet usable.
     Verification of the download is in progress.
     */
    case verifying
    /**
     The offline pack is expired and can't be used until it is refreshed.
     The file on disk must not be used.
     */
    case expired
    /**
     The download failed or is unusable.
     Check the `error` field for a more detailed status code.
     The file on disk is unusable.
     */
    case errored(error: OfflineRegionError)
    /**
     The download is marked for deleting.
     Code that is currently still using the file should cease to do so as soon as possible and
     once finished, acknowledge receipt of this status update. Offline packs in this state should
     no longer be shown to the user, and code shouldn't start using them.
     */
    case deleting
    /**
     The download has been deleted
     */
    case deleted

    public static func == (lhs: OfflineRegionStatus, rhs: OfflineRegionStatus) -> Bool {
        switch lhs {
        case .pending:
            switch rhs {
            case .pending:
                return true
            default:
                return false
            }
        case .downloading:
            switch rhs {
            case .downloading:
                return true
            default:
                return false
            }
        case .available:
            switch rhs {
            case .available:
                return true
            default:
                return false
            }
        case .incomplete:
            switch rhs {
            case .incomplete:
                return true
            default:
                return false
            }
        case .verifying:
            switch rhs {
            case .verifying:
                return true
            default:
                return false
            }
        case .expired:
            switch rhs {
            case .expired:
                return true
            default:
                return false
            }
        case .errored(error: let lError):
            switch rhs {
            case .errored(error: let rError):
                return lError == rError
            default:
                return false
            }
        case .deleting:
            switch rhs {
            case .deleting:
                return true
            default:
                return false
            }
        case .deleted:
            switch rhs {
            case .deleted:
                return true
            default:
                return false
            }
        }
    }
}
