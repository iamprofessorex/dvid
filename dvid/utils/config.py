# config.py

# Configuration file in which some paths, URLs and other constants are defined


import logging
import os
## Required packages
from pathlib import Path

from dvid.dvid_logger import get_logger  # noqa: E402

LOGGER = get_logger(__name__, provider="Config", level=logging.DEBUG)


## Initialization of the first time using facebook_downloader_1 alternative
firstTimeFB1Alt = True
firstTimeLoggedInInsta = True


## Configurations
DOWNLOAD_DIRECTORY = os.path.expanduser(
    "~/Downloads/dvid"
)  # name of the folder in which we will put the downloaded video files (this can be adjusted by the user)
DEFAULT_DOWNLOAD_DIRECTORY = str(Path.home() / "Downloads" / "dvid")
GOOGLE = "https://www.google.com/"
TEAM_STAMA = "https://www.teamstama.com/"
YTMP3_URL = "https://ytmp3.cc/"
SAVE_AS_URL = "https://saveas.co"
GET_FVID_URL = "https://www.getfvid.com"
EXPERTS_PHP_INSTA = "https://www.expertsphp.com/instagram-reels-downloader.php"
SNAP_TIK = "https://snaptik.app"
SAVE_FROM_INSTA = "https://en.savefrom.net/download-from-instagram"
SAVE_FROM_DAILYMOTION = (
    "https://en.savefrom.net/10-how-to-download-dailymotion-video.html"
)
EXPERTS_PHP_PINT = "https://www.expertsphp.com/pinterest-video-downloader.html"


LOGGER.debug(f"DOWNLOAD_DIRECTORY = {DOWNLOAD_DIRECTORY}")
LOGGER.debug(f"DEFAULT_DOWNLOAD_DIRECTORY = {DEFAULT_DOWNLOAD_DIRECTORY}")
LOGGER.debug(f"GOOGLE = {GOOGLE}")
LOGGER.debug(f"TEAM_STAMA = {TEAM_STAMA}")
LOGGER.debug(f"YTMP3_URL = {YTMP3_URL}")
LOGGER.debug(f"SAVE_AS_URL = {SAVE_AS_URL}")
LOGGER.debug(f"GET_FVID_URL = {GET_FVID_URL}")
LOGGER.debug(f"EXPERTS_PHP_INSTA = {EXPERTS_PHP_INSTA}")
LOGGER.debug(f"SNAP_TIK = {SNAP_TIK}")
LOGGER.debug(f"SAVE_FROM_INSTA = {SAVE_FROM_INSTA}")
LOGGER.debug(f"SAVE_FROM_DAILYMOTION = {SAVE_FROM_DAILYMOTION}")
