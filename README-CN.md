# 使用 Gcov 和 LCOV 对 C/C++ 项目做代码覆盖率测试

[English Readme](README.md)

## 问题

如果你的 C/C++ 项目没有单元测试代码，而你还想做代码覆盖率测试怎么办？

市面上有一些这些针对 C/C++ 项目代码覆盖率测试的工具，但绝大多数都是收费的。

我在很久之前调研过一款收费的 C/C++ 代码覆盖率工具 [Squish Coco](https://shenxianpeng.github.io/2019/05/squishcoco/)，由于当时有一些编译问题没有解决，就搁置没有购买。

当我重新又开始了关于 C/C++ 项目的代码覆盖率测试的工作时了解到 GCC 实际上提供了代码覆盖率的编译选项 `-fprofile-arcs` 和 `-ftest-coverage`，为了弄清楚 [Gcov](https://gcc.gnu.org/onlinedocs/gcc/Gcov.html) 是如何工作的做了一些调查，并把这个调查过程做了如下整理。

## 前提

如果需要运行这个示例仓库的程序，您的环境需要预先安装了 [gcc](https://gcc.gnu.org/install/index.html) 和 [lcov](http://ltp.sourceforge.net/coverage/lcov.php)。

## 关于分支

`master` 分支里仅存放的是需要演示所用到的 `.c` `.h` `makefile` 等文件。

`coverage` 分支保存了所有的编译过程中生成的文件，以及最后的代码覆盖率 HTML 报告文件(在 `out` 目录下)。

## 生成代码覆盖率

如果想亲自生成代码覆盖率，只需要执行如下 3 步：

```bash
# step 1 编译
make

# step 2 运行程序
./main

# step 3 生成报告
make report

# 删除上述生成所有文件
make clean
```

以上命令实际是通过 `makefile` 将一些需要执行的命令放到一起来执行的，具体细节可参看下方步骤。

### 1. 编译

```bash
$ make
# 加入 -fprofile-arcs -ftest-coverage 这两个编译选项之后的输出
gcc -fPIC -fprofile-arcs -ftest-coverage -c -Wall -Werror -fpic main.c
gcc -fPIC -fprofile-arcs -ftest-coverage -c -Wall -Werror -fpic foo.c
gcc -fPIC -fprofile-arcs -ftest-coverage -o main main.o foo.o
```

再看一下仓库下有多了哪些文件

```bash
$ ls
foo.c  foo.gcno  foo.h  foo.o  img  main.c  main.exe  main.gcno  main.o  makefile  README.md  README-CN.md
```

在编译完成后，除了生成 `main`, `.o` 之外，还多了两个 `.gcno` 文件。`.gcno` 是注释文件，在加入 `-ftest-coverage` 选项编译源文件时产生的，它包含了重建基本块图和给块分配源行号的信息。

### 2. 运行可执行文件

因为程序在编译过程中加入了 `-fprofile-arcs` 和 `-ftest-coverage` 这两个选项，在运行生成的可行性文件 `main` 之后，它的运行数据就被记录了下来，并生成计数数据文件(`.gcda`)。

```bash
$ ./main
Start calling foo() ...
when num is equal to 1...
when num is equal to 2...

# 在 main 被执行后，生成了两个 .gcda 文件
$ ls
foo.c  foo.gcda  foo.gcno  foo.h  foo.o  img  main.c  main.exe  main.gcda  main.gcno  main.o  makefile  README.md  README-CN.md
```

> 官方称 `.gcda` 文件记录的是 arc transition counts, value profile counts（这两个英文不知道该如何翻译）和一些摘要信息。

### 3. 生成报告

最后执行 `make report` 生成最终的 HTML 报告，它实际做了以下几件事：

第一，生成报告文件

当有了 `.gcno` 和 `.gcda` 这两个文件之后，通过 `gcov` 命令生成报告文件，即执行 `gcov main.c foo.c` 生成 `.gcov` 文件。

```bash
gcov main.c foo.c
File 'main.c'
Lines executed:100.00% of 5
Creating 'main.c.gcov'

File 'foo.c'
Lines executed:85.71% of 7
Creating 'foo.c.gcov'

Lines executed:91.67% of 12
```

第二，生成 HTML 报告

上面的输出虽然已经可以知道了 `main.c` 和 `foo.c` 这两个源文件的代码覆盖率，但是不够直观，也不能看到具体是哪一行没有执行到，LCOV 这个工具可以帮助我们生成更加直观的 HTML 报告。

> LCOV 是 GCC 的覆盖率测试工具 gcov 的一个图形化前端，它收集多个源文件的 gcov 数据来创建含有覆盖率信息注释的源代码的 HTML 页面，它提供了概览页面，支持语句、函数和分支覆盖率的信息。

首先通过 `lcov --capture --directory . --output-file coverage.info` 命令来生成 coverage.info 数据文件。

```bash
$ lcov --capture --directory . --output-file coverage.info
Capturing coverage data from .
Found gcov version: 4.8.5
Scanning . for .gcda files ...
Found 2 data files in .
Processing foo.gcda
Processing main.gcda
Finished .info-file creation
```

然后执行 `genhtml coverage.info --output-directory out` 生成 HTML 报告。

```bash
$ genhtml coverage.info --output-directory out
Reading data file coverage.info
Found 2 entries.
Found common filename prefix "/workspace/coco"
Writing .css and .png files.
Generating output.
Processing file gcov-example/main.c
Processing file gcov-example/foo.c
Writing directory view page.
Overall coverage rate:
  lines......: 91.7% (11 of 12 lines)
  functions..: 100.0% (2 of 2 functions)
```


## 代码覆盖率报告

![index](img/index.png)

![example](img/example.png)

![main.c](img/main.c.png)

![foo.c](img/foo.c.png)

注：git checkout 到 `coverage` 分支下的 `out` 目录进行查看或下载报告。


## 参考

在此次调查中涉及的一些有用的文档：

* Gcov 主页：https://gcc.gnu.org/onlinedocs/gcc/Gcov.html
* Lcov 主页：http://ltp.sourceforge.net/coverage/lcov.php

* gcovr 主页：https://github.com/gcovr/gcovr（另外一个可以生成 HTML 用 Python 实现的工具，在报告展示上与 Lcov 略有不同。）

* Gcov 数据文件重定向
    * https://gcc.gnu.org/onlinedocs/gcc/Cross-profiling.html#Cross-profiling
    * https://stackoverflow.com/questions/7671612/crossprofiling-with-gcov-but-gcov-prefix-and-gcov-prefix-strip-is-ignored

* Linux kernel 使用 gcov：https://01.org/linuxgraphics/gfx-docs/drm/dev-tools/gcov.html
