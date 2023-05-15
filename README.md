# zig-http-playground

Playground for different ways of configuring and using Zig std.http.Server

Use this for experimenting and benchmarking different options

Not intended for production use - this is just a playground to see whats fast, what isnt, and what breaks under load

## Install / Build

```
git@github.com:zigster64/zig-http-playground.git
cd zig-http-playground
zig build
```


## Run it

`zig-http-playground THREADMODE FILE-IO-MODE PORT`

Where `THREADMODE` in singlethread, threadpool2, threadpoolmax, threadperconnection

Where `FILE-IO-MODE` in code, os

Where `PORT` = the port to run on (eg 8080)

Running Example :
```
zig-http-playground singlethread code 8080
```

Using makefile :

To show all the ways of running it, just run :
```
make
```

examples :
```
make run-single
```

## Thread Modes

singlethread - simple and fast, just do the accept() / handler() in a simple loop.
https://github.com/zigster64/zig-http-playground/blob/main/src/single_thread.zig

threadpool2 - accept in a loop, run the handlers in a threadpool of 2 threads

threadpoolmax - accept in a loop, run the handlers in a threadpool of std.Thread.getCpuCount() threads

theadperconnection - accept in a loop, spawn a whole new thread for each connection, to see where it melts down.  Dont do this in production !

## File IO Modes

code - simple Zig code to read the file using stdlib, and write the contents to the response.

os - open the file using Zig stdlib, but then use the std.os.sendfile() to get the kernel to do the IO from the file to the socket


## Benchmarks - Zig File IO, using simple connections vs keepalives

Mac M2 pro / 16GB

`siege -t 10S -c 10  -b http://localhost:8080/`

Concurrency 10 users
Duration 10 seconds
Benchmark mode (no delay between requests)


### singlethread
Comments - this should give good avg performance

Transaction rate:	     1632.27 trans/sec
Throughput:		        7.00 MB/sec
Concurrency:		        4.63

- with keepalive :

Transaction rate:	     3420.11 trans/sec
Throughput:		       14.66 MB/sec
Concurrency:		        1.97

### threadpool2
Comments - this should slightly less throughput, but slightly better concurrency

Transaction rate:	     1621.95 trans/sec
Throughput:		        6.95 MB/sec
Concurrency:		        6.10

- with keepalive :

Transaction rate:	     3531.05 trans/sec
Throughput:		       15.14 MB/sec
Concurrency:		        1.97

### threadperconnection
Comments - expecting this to meltdown, but it held up better than expected
I guess thats due to having only a really short life on the thread

Transaction rate:	      570.21 trans/sec
Throughput:		        2.44 MB/sec
Concurrency:		        8.99

- with keepalive :

Transaction rate:	     2652.42 trans/sec
Throughput:		       11.37 MB/sec
Concurrency:		        9.98

### threadpoolmax
Comments - expecting better throughput and concurrency than having a pool of 2 threads, 
           but in reality it melted down pretty quick

Transaction rate:	     1096.52 trans/sec
Throughput:		        4.70 MB/sec
Concurrency:		        4.94

- with keepalive :

Transaction rate:	     2644.48 trans/sec
Throughput:		       11.34 MB/sec
Concurrency:		        9.98


## Benchmarks - std.os.sendfile Mode

Mac M2 pro / 16GB

`siege -t 10S -c 10 -b http://localhost:8080`

Concurrency 10 users
Duration 10 seconds
Benchmark mode (no delay between requests)

### singlethread

Transaction rate:	     1572.86 trans/sec
Throughput:		        6.74 MB/sec
Concurrency:		        4.36

- keepalive :

Transaction rate:	     3083.15 trans/sec
Throughput:		       13.22 MB/sec
Concurrency:		        0.97

### threadpool2

Transaction rate:	     1490.97 trans/sec
Throughput:		        6.39 MB/sec
Concurrency:		        5.39

- keepalive :

Transaction rate:	     2737.78 trans/sec
Throughput:		       11.74 MB/sec
Concurrency:		        1.98

### threadperconnection
Comment - server crashes under load, as expected
Numbers represent what siege saw before the server melted down

Transaction rate:	     1363.36 trans/sec
Throughput:		        5.85 MB/sec
Concurrency:		        9.98

- keepalive :

Transaction rate:	     2690.94 trans/sec
Throughput:		       11.54 MB/sec
Concurrency:		        9.97

### threadpoolmax

Transaction rate:	     1582.66 trans/sec
Throughput:		        6.79 MB/sec
Concurrency:		        7.62

- keepalive :

Transaction rate:	     2532.95 trans/sec
Throughput:		       10.86 MB/sec
Concurrency:		        9.97
