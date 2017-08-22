# Enhance Video Streaming Performance for Android

* Proposal: [SDL-0069](0069-enhance-video-streaming-performance-for-android.md)
* Author: [BrandonHe](https://github.com/BrandonHe)
* Status: **Rejected**
* Impacted Platforms: [Android]

## Introduction

This proposal aims to enhance SDL Android library for massive data transmission performance for video streaming and projection by refactor default I/O pipe write/read class.

## Motivation

The SDL Android library are currently using default java.io package, it uses `PipedInputStream` via `write()` function to stream data **Byte by Byte**, because CPU operation is very fast, in most cases, the operation performs as good as we expected. But for video streaming and projection, it is a bottleneck for transmission according to test. It will cause very frequent CPU resources switch between read thread and write thread. Thus has an effect on video streaming performance. Another motivation here is that if read thread get the critical resource to read after write thread just write one byte or serveral bytes, this leads to slice one frame data to send by many times. It also reduces the efficiency of data transmission and increase the CPU workload.

## Proposed solution

The solution in this proposal is to refactor the class `PipedInputStream` and  the class `PipedOutputStream`, it gives parameter byteOffset and parameter byteCount in receive function and write function. These will help these two functions to call `System.arraycopy()` to receive and write block data into buffer one time.

Currently, we send data via write function as below:

```java
@Override
public void write(int oneByte) throws IOException {
    PipedInputStream stream = target;
    if (stream == null) {
        throw new IOException("Pipe not connected");
    }
    stream.receive(oneByte);
}
```

There is a better way to write data to PipedInputStream: read the length of write buffer one time and write bytes in buffer via `System.arraycopy(bytes, offset, buffer, in, bytesToTransfer)` instead of byte by byte. For more code details, please refer [here](http://grepcode.com/file/repository.grepcode.com/java/root/jdk/openjdk/6-b14/java/io/PipedInputStream.java#226)

Due to the fact that we have tested, the video streaming performance is enhanced.

For `receive()` array function:
```java
/**
 * Receives an array of bytes
 * @param bytes data
 * @param byteOffset offset of the data
 * @param byteCount count of data
 * @throws IOException
 */
synchronized void receive(byte[] bytes, int byteOffset, int byteCount) throws IOException {
    checkStateForReceive();
    this.writeSide = Thread.currentThread();
    int bytesToTransfer = byteCount;
    while (bytesToTransfer > 0) {
        if (this.in == this.out) {
            awaitSpace();
        }
        int nextTransferBytes = 0;
        if (this.out < this.in) {
            nextTransferBytes = this.buffer.length - this.in;
        } else if (this.in < this.out) {
            if (this.in == -1) {
                this.in = this.out = 0;
                nextTransferBytes = this.buffer.length - this.in;
            } else {
                nextTransferBytes = this.out - this.in;
            }
        }
        if (nextTransferBytes > bytesToTransfer) {
            nextTransferBytes = bytesToTransfer;
        }
        System.arraycopy(bytes, byteOffset, this.buffer, this.in, nextTransferBytes);
        bytesToTransfer -= nextTransferBytes;
        byteOffset += nextTransferBytes;
        this.in += nextTransferBytes;
        if (this.in >= this.buffer.length) {
            this.in = 0;
        }
    }
    notifyAll();
}
```

For `write()` array function:
```java
/**
 * Write an array of bytes
 * @param bytes array of data
 * @param byteOffset offset of array
 * @param byteCount count of data
 * @throws IOException
 */
public void write(byte[] bytes, int byteOffset, int byteCount) throws IOException {
    if (this.sink == null) {
        throw new IOException("Pipe not connected");
    }else if (bytes == null) {
        throw new NullPointerException();
    }else if ((byteOffset < 0) || (byteOffset > bytes.length) || (byteCount < 0)
            || (byteOffset + byteCount > bytes.length) || (byteOffset + byteCount < 0)) {
        throw new IndexOutOfBoundsException();
    }else if (byteCount == 0) {
        return;
    }
    this.sink.receive(bytes, byteOffset, byteCount);
}

```

## Potential downsides

N/A

## Impact on existing code

There is no impact for the existing code. The changes in this proposal are to remove the default io PipedInputStream and PipedOutputStream package and reimport PipedInputStream and PipedOutputStream from component streaming. The developer would not need to change their previous code if they do not wish to use the new library for video streaming.
 
## Alternatives considered

There is a optional solution to improve the video streaming performance by directly sending data from encoder byte buffer and handler to avoid using the pipe stream.
