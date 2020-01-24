# LinkedIn Live Video Downloader

This repository contains a script that I've used to download LinkedIn Live videos.

To use the script, modify the `PUBLIC_URL` and `VIDEO_ID` variables in `linkedin.sh`.

---
title: Downloading LinkedIn Live Videos
published: false
description: 
tags: linkedin,hack,download
---

I [gave a talk recently at a community meetup](https://www.linkedin.com/video/live/urn:li:ugcPost:6608309192438710272/) where they were using the fancy new [LinkedIn Live](https://www.linkedin.com/help/linkedin/answer/100225/getting-started-with-linkedin-live?lang=en) to stream the event. Post-event, I decided I wanted a copy of the video but LinkedIn didn't seem to agree with me that I should have a copy of my video. Also, none of the existing *video downloader* websites worked, and none of the advice given by other folks online did too. Apparently LinkedIn had changed the way they did videos. So. The network tab it was! 

> This short post documents how I managed to download a LinkedIn video with a little hacking on the Chrome Console and shell scripts. You should be comfortable with the command line for things to work out.

## Getting to the Target

So you've seen a LinkedIn post with a video that you want locally available. We begin by clicking on the video so that it opens up in a theatre-like mode. For my video, the URL looked like:

```
https://www.linkedin.com/video/live/urn:li:ugcPost:%UGC_POST_ID%/
```

## Observing the Target

Once the page is loaded, **do not hit play** - open the Chrome Console and go to the Network tab. Now hit play and look out on the Network tab for a `manifest(format=m3u8-aapl-v3)` call. This call seems to be making a request to retrieve the possible variants of the video and the response should look similar to:

```
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-STREAM-INF:BANDWIDTH=351536,RESOLUTION=340x192,CODECS="avc1.64000d,mp4a.40.5"
QualityLevels(200000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=709236,RESOLUTION=384x216,CODECS="avc1.640015,mp4a.40.5"
QualityLevels(550000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=1015836,RESOLUTION=512x288,CODECS="avc1.640015,mp4a.40.5"
QualityLevels(850000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=1526836,RESOLUTION=704x396,CODECS="avc1.64001e,mp4a.40.5"
QualityLevels(1350000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=2395536,RESOLUTION=960x540,CODECS="avc1.64001f,mp4a.40.5"
QualityLevels(2200000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=3724136,RESOLUTION=1280x720,CODECS="avc1.64001f,mp4a.40.5"
QualityLevels(3500000)/Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXT-X-STREAM-INF:BANDWIDTH=138976,CODECS="mp4a.40.5"
QualityLevels(128000)/Manifest(audio_und,format=m3u8-aapl-v3)
```

The above manifest is used to determine what `QualityLevel` should be streamed when the `BANDWIDTH` is above a certain rate. We'll see how that is used later.

## Meeting the Target

The next request of interest which should come shortly after the above request is completed should have the name `Manifest(video,format=m3u8-aapl-v3,audiotrack=audio_und)`. Clicking on it and going to the Response tab, you should see a huge file that consists of lines like these:

```
...
#EXTINF:2.000000,no-desc
Fragments(video=%FRAGMENT_ID_1%,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXTINF:2.000000,no-desc
Fragments(video=%FRAGMENT_ID_2%,format=m3u8-aapl-v3,audiotrack=audio_und)
#EXTINF:2.000000,no-desc
Fragments(video=%FRAGMENT_ID_3%,format=m3u8-aapl-v3,audiotrack=audio_und)
...
```

These apparently define the list of video fragments that stream through your browsers to form the full video.

Looking slightly below the above request, you'll find network calls named `Fragments(video=%FRAGMENT_ID%,format=m3u8-aapl-v3,audiotrack=audio_und)`. Well, doesn't that look familiar?

Check out the full URL of the call (right click on row, copy as cURL) of those requests and you should find it resembles the following format:

```
https://streamwus2-livectorprodmedia11-usw22.licdn.com/%UUID%/%SOME_VIDEO_ID%-livemanifest.ism/QualityLevels(2200000)/Fragments(video=%FRAGMENT_ID%,format=m3u8-aapl-v3,audiotrack=audio_und)
```

Notice the `QualityLevels` and `Fragments`. This is the call that retrieves the fragments of data that are collated to form your video.

## Obtaining the Target

So we now know how the video is being streamed, we can replicate this minimally by:

1. Visit the video page, open network tab
2. Look out for call to `manifest...`, note the `QualityLevel`
3. Look out for the subsequent call to `Manifest...`, copy the URL as a cURL command
4. Referencing the `QualityLevel`s from step 2, modify the URL in the cURL request so that it's of the highest quality
5. Run the cURL command and pipe it to a `manifest` file.
6. You can extract all the fragment IDs using `cat ./manifest | grep -v '#' | cut -f 2 -d '=' | cut -f 1 -d ',' > ./fragment_ids`
7. Iterate through the list of fragments and issue a cURL request for each, piping the output to a file incrementally. That would look like:

```sh
touch video.mp4
while read FRAGMENT_ID; do
  echo 'processing ${FRAGMENT_ID}';
  curl ... >> video.mp4
done <./fragment_ids;
```





















