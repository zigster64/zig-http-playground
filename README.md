# zig-http-playground

Playground for different ways of configuring and using Zig std.http.Server 
(using the new std.http.Server library in zig 0.11.x)

Use this for experimenting and benchmarking different options

Not intended for production use - this is just a playground to see whats fast, what isnt, and what breaks under load

You will need to be running the latest 0.11.x dev version of Zig to play with this

## Install / Build

```
git@github.com:zigster64/zig-http-playground.git
cd zig-http-playground
zig build
```


## Run it

`zig-http-playground THREADMODE FILE-IO-MODE PORT`

Where `THREADMODE` in singlethread, threadpool2, threadpoolmax, threadmadness

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

[singlethread](https://github.com/zigster64/zig-http-playground/blob/main/src/single_thread.zig) - simple and fast, just do the accept() / handler() in a simple loop.

[threadpool2](https://github.com/zigster64/zig-http-playground/blob/main/src/thread_pool.zig) - accept in a loop, run the handlers in a threadpool of 2 threads

[threadpoolmax](https://github.com/zigster64/zig-http-playground/blob/main/src/thread_pool.zig) - accept in a loop, run the handlers in a threadpool of std.Thread.getCpuCount() threads

[threadmadness](https://github.com/zigster64/zig-http-playground/blob/main/src/thread_madness.zig) - accept in a loop, spawn a whole new thread for each connection, to see where it melts down.  Dont do this in production !

## File IO Modes

code - simple Zig code to read the file using stdlib, and write the contents to the response.

os - open the file using Zig stdlib, but then use the std.os.sendfile() to get the kernel to do the IO from the file to the socket


## Benchmark Run

Mac M2 pro / 16GB

Hitting the server with 

`siege -t 10S -c 10  -b http://localhost:8080/`

- Concurrency 10 users
- Duration 10 seconds
- Benchmark mode (no delay between requests)

## Benchmark Results

WARNING - benchmarks are benchmarks ... dont go reading too much into the results, just use them to get a rough understanding of what goes where.

Figures can vary wildly from run to run.

There doesnt seem to be any significant difference between compiling with debug vs compiling with releaseFast on the Zig side.

Rust is marginally better on release build vs debug build.

Surprised that the Go stdlib doesnt handle keepalive !!
Or that nodejs serve / python http.server also dont handle keepalive.

- Transactions = Transactions per second
- Throughput = MB per sec
- Concurrency = Avg number of active simultaneous users

### Other non-Zig Things on same machine to benchmark against

| Mode               | Trans/Sec | MB/s | Conc | Keepalive/Sec | Keepalive MB/s | Keepalive Con |
| :---               |      ---: | ---: |  --: |          ---: |           ---: |          ---: |
| nodejs serve       | 1516 | 0.07 | 5.41 | FAIL | FAIL | FAIL |
| python3 | 1606 | 6.89 | 4.22 | FAIL | FAIL | FAIL |
| go  | 1551 | 3.33 | 3.80 | FAIL | FAIL | FAIL | 
| rust debug | 1143 | 4.90 | 4.42 | N/A | N/A | N/A |
| rust release | 1596 | 6.85 | 4.54 | N/A | N/A | N/A |


### Using Zig File IO 

| Mode               | Trans/Sec | MB/s | Conc | Keepalive/Sec | Keepalive MB/s | Keepalive Con |
| :---               |      ---: | ---: |  --: |          ---: |           ---: |          ---: |
| singlethread       | 1632 | 7.10 | 4.63 | 3220 | 14.66 | 1.97 | 
| threadpool2        | 1621 | 6.95 | 6.10 | 3531 | 15.14 | 1.97 | 
| threadpoolmax      | 1096 | 4.70 | 4.94 | 2644 | 11.34 | 9.98 |
| threadmadness      | 570 | 2.44 | 8.99 | 2652 | 11.37 | 9.98 |

### Zig Using std.os.sendfile 

| Mode               | Trans/Sec | MB/s | Conc | Keepalive/Sec | Keepalive MB/s | Keepalive Con |
| :---               |      ---: | ---: |  --: |          ---: |           ---: |          ---: |
| singlethread       | 1572 | 6.74 | 4.36 | 3083 | 18.22 | 0.97 |
| threadpool2        | 1490 | 6.39 | 5.39 | 2738 | 11.74 | 1.98 |
| threadpoolmax      | 1582 | 6.79 | 7.62 | 2632 | 10.86 | 9.97 |
| threadmadness      | 1363 | 5.85 | 9.98 | 2690 | 11.54 | 9.97 |

