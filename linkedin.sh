#!/bin/sh
set -e;

# the url of the video
PUBLIC_URL='https://www.linkedin.com/video/live/urn:li:ugcPost:6608309192438710272/';
echo "PUBLIC_URL: ${PUBLIC_URL}";

# search for this and manually copy it out from the request named `manifest(...`
VIDEO_ID='675d5825-3a72-4aae-ba1b-e444a9300ee9/L565bb568d642c2a000-livemanifest.ism';
echo "VIDEO_ID: ${VIDEO_ID}";

OUTPUT_PATH='./output/video.mp4';

curl "https://streamwus2-livectorprodmedia11-usw22.licdn.com/${VIDEO_ID}/manifest(format=m3u8-aapl-v3)" \
		-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36' \
		-H "Referer: ${PUBLIC_URL}" \
		-H 'Origin: https://www.linkedin.com' --compressed \
		> ./data/quality_manifest;

QUALITY_LEVEL="$(cat ./data/quality_manifest | grep -v '#' | cut -f 2 -d '(' | cut -f 1 -d ')' | sort -n | tail -n 1)";
echo "QUALITY_LEVEL: ${QUALITY_LEVEL}";

curl "https://streamwus2-livectorprodmedia11-usw22.licdn.com/${VIDEO_ID}/QualityLevels(${QUALITY_LEVEL})/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)" \
	-H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36' \
	-H "Referer: ${PUBLIC_URL}" \
	-H 'Origin: https://www.linkedin.com' --compressed \
	> ./data/video_manifest;

FRAGMENT_IDS=$(cat ./data/video_manifest | grep -v '#' | cut -f 2 -d '=' | cut -f 1 -d ',');
printf "${FRAGMENT_IDS}" > ./data/fragment_ids;
echo "N_FRAGMENTS: $(printf "${FRAGMENT_IDS}" | wc -l)";

echo "OUTPUT_PATH: ${OUTPUT_PATH}";
rm -rf ${OUTPUT_PATH};
touch ${OUTPUT_PATH};

while read FRAGMENT_ID; do
  echo "DOWNLOADING FRAGMENT[$FRAGMENT_ID]...";
  curl "https://streamwus2-livectorprodmedia11-usw22.licdn.com/${VIDEO_ID}-livemanifest.ism/QualityLevels(${QUALITY_LEVEL})/Fragments(video=${FRAGMENT_ID},format=m3u8-aapl-v3,audiotrack=audio_und)" \
    -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.117 Safari/537.36' \
    -H "Referer: ${PUBLIC_URL}" \
    -H 'Origin: https://www.linkedin.com' \
    --compressed >> ./video.mp4;
done <data/fragment_ids;
