FROM alpine:latest

# Download the standard alpine iso file. Use pinned version.
ADD https://dl-cdn.alpinelinux.org/alpine/v3.16/releases/x86_64/alpine-standard-3.16.2-x86_64.iso alpine.iso

# Download the headless setup overlay file and put it in ./alpine. Use pinned version.
ADD https://github.com/macmpi/alpine-linux-headless-bootstrap/blob/9141ed77ee4a6b1784069d245f345dc632825a95/headless.apkovl.tar.gz alpine/

RUN apk update \
  && apk add p7zip

# Extract the iso image as files
RUN 7z x -y -oalpine alpine.iso 

RUN apk update && apk add xorriso

# Copy ./alpine into the root directory of the alpine standard ISO image
RUN xorrisofs \
  # Enable Rock Ridge and set to read-only for everybody
  -rational-rock \
  # Add Joliet attributes for Microsoft systems
  -joliet \
  # Write the resulting image to a file
  -output out.iso \
  # Enable Rock Ridge and set to read-only for everybody
  -rational-rock \
  alpine

CMD [ "cat", "out.iso" ]
