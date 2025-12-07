<?php
require_once realpath(__DIR__ . '/ip_mapping.php');

if (isset($_GET['video'])) {
    $video = $_GET['video'];
} else {
    echo "No video file provided.";
    exit;
}

$IPAddr = $_SERVER["REMOTE_ADDR"];

// Load the IP mapping
error_log("ipMappingFile: {$ipMappingFile}");
$ipMapping = loadIpMapping($ipMappingFile);

// Replace IP with text if available
error_log("IPAddr: {$IPAddr}");
$displayIP = replaceIpWithText($IPAddr, $ipMapping);
error_log("displayIP: {$displayIP}");
?>
<!DOCTYPE html>
<html>

<head>
    <title><?php echo basename($video); ?></title>
    <style>
        body {
            margin: 0;
            overflow: hidden;
            background-color: black;
        }

        video {
            width: 100vw;
            object-fit: contain;
        }

        #resumeButton {
            display: none;
            padding: 10px 20px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
            margin-top: 20px;
        }
    </style>
</head>

<body>
    <video id="video" controls width="100%" height="auto" autoplay>
        <?php $src = "<source src=\"$video\" type=\"video/mp4\">";
        echo $src; ?>
        Your browser does not support the video tag.
    </video>
    <script>
        const videoID = document.getElementById('video');
        const videoFile = videoID.querySelector('source').getAttribute('src');

        let startTime = 0;
        let totalTimeWatched = 0;
        let isPlaying = false;
        let videoStarted = false;
        let videoEnded = false;
        let isSeeking = false;
        let seekTimeout = null;

        function setVideoDimensions() {
            const screenWidth = window.innerWidth;
            const screenHeight = window.innerHeight;
            const videoAspectRatio = 16 / 9;
            let videoWidth = screenWidth;
            let videoHeight = screenWidth / videoAspectRatio;

            if (videoHeight > screenHeight) {
                videoHeight = screenHeight;
                videoWidth = screenHeight * videoAspectRatio;
            }

            videoID.width = Math.round(videoWidth);
            videoID.height = Math.round(videoHeight);
        }

        setVideoDimensions();
        window.addEventListener('resize', setVideoDimensions);

        videoID.addEventListener('canplay', () => {
            let lastCurrentTime = localStorage.getItem('lastCurrentTime');
            // Check if the video has been re-initialized (currentTime reset to 0)
            if (videoID.currentTime === 0 && lastCurrentTime > 0) {
                videoID.currentTime = lastCurrentTime; // Reset the currentTime
                videoID.play().catch(error => {
                    logmsg('Error attempting to resume playback: ' + error);
                });
            }
        });

        videoID.addEventListener('play', () => {
            isPlaying = true;
            if (!videoStarted) {
                videoStarted = true;
                logmsg('Started for the first time @ ' + Math.round(startTime) + ' seconds');
            } else {
                logmsg('Resumed @ ' + Math.round(videoID.currentTime) + ' seconds');
            }
            localStorage.setItem('lastCurrentTime', videoID.currentTime);
            resumeButton.style.display = 'none';
        });

        videoID.addEventListener('pause', () => {
            if (isPlaying && !isSeeking && !videoEnded) {
                totalTimeWatched = videoID.currentTime - startTime;
                logmsg('Paused  @ ' + Math.round(totalTimeWatched) + ' seconds');
            }
            localStorage.setItem('lastCurrentTime', videoID.currentTime);
            isPlaying = false;
        });

        videoID.addEventListener('seeking', () => {
            isSeeking = true;
            clearTimeout(seekTimeout);
        });

        videoID.addEventListener('seeked', () => {
            clearTimeout(seekTimeout);
            seekTimeout = setTimeout(() => {
                isSeeking = false;
                logmsg('Seeked to ' + Math.round(videoID.currentTime) + ' seconds');
                if (isPlaying) {
                    totalTimeWatched += videoID.currentTime - startTime;
                    startTime = videoID.currentTime;
                }
            }, 200);
        });

        videoID.addEventListener('ended', () => {
            videoEnded = true;
            logmsg('Ended   @ ' + Math.round(videoID.currentTime) + ' seconds');
            localStorage.removeItem('lastCurrentTime');
        });

        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'hidden') {
                //localStorage.setItem('lastCurrentTime', videoID.currentTime);
                //debug('setItem localStorage.lastCurrentTime: ' + localStorage.getItem('lastCurrentTime'));
                videoID.pause();
            } else if (document.visibilityState === 'visible') {
                let lastCurrentTime = localStorage.getItem('lastCurrentTime');
                if (lastCurrentTime > 0) {
                    videoID.currentTime = lastCurrentTime;
                    if (lastCurrentTime > 0) {
                        resumeButton.style.display = 'block';
                    }
                }
            }
        });

        function logmsg(msg) {
            const fileType = 'Video';
            const xhr = new XMLHttpRequest();
            const IPAddr = "<?php echo $displayIP; ?>";
            const data = {
                IPAddr: IPAddr,
                fileType: fileType,
                file: videoFile,
                msg: msg,
            };

            xhr.open('POST', 'https://defaria.com:3000/log-playback', true);
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.send(JSON.stringify(data));
        }

        function debug(msg) {
            return;
            logmsg("DEBUG: " + msg);
        }

        window.addEventListener('beforeunload', (event) => {
            event.preventDefault();
            event.returnValue = '';

            if (!videoEnded) {
                totalTimeWatched += videoID.currentTime - startTime;
                logmsg('user bailed @ ' + Math.round(totalTimeWatched) + ' seconds');
            }
            localStorage.setItem('lastCurrentTime', 0);
        });

    </script>
</body>

</html>