OCNet is a nightmare to install, apparently, on whatever version of R and MacOS and Apple chip that I have. So here is my workflow:

# Configure compilers on Apple silicon (M1, M2, M3, ...) for Rcpp
C and Fortran are used heavily in OCNet for various backend functions, but the cpp and fortran compilers need to be installed in a specific way for R to be able to use them and to successfully install OCNet.

I follwed the instructions in this stackexchange post: https://stackoverflow.com/questions/70638118/configuring-compilers-on-apple-silicon-m1-m2-m3-for-rcpp-and-other-tool

1. Download an R 4.4 binary from CRAN here and install. Be sure to select the binary built for Apple silicon.

    Run

    ```bash
    $ sudo xcode-select --install
    ```

    in Terminal to install the latest release version of Apple's Command Line Tools for Xcode (well, the latest one supporting your version of macOS), which includes Apple Clang. You can obtain older versions from your browser here. CRAN builds R 4.4 for macOS 11.0 and newer using Xcode 14.2 or 14.3.

2. Download the GNU Fortran binary provided here and install by unpacking to root:

    ```bash
    $ curl -LO https://github.com/R-macos/gcc-12-branch/releases/download/12.2-darwin-r0/gfortran-12.2-darwin20-r0-universal.tar.xz
    $ sudo tar xvf gfortran-12.2-darwin20-r0-universal.tar.xz -C /
    $ sudo ln -sfn $(xcrun --show-sdk-path) /opt/gfortran/SDK
    $ rm gfortran-12.2-darwin20-r0-universal.tar.xz
    ```

    The last command updates a symlink inside of the installation so that it points to an SDK inside of your Command Line Tools installation.
3. Download an OpenMP runtime library suitable for your Apple Clang version here and install by unpacking under /opt/R/arm64/ after stripping the usr/local/ prefix. You can query your Apple Clang version with clang --version. For example, I have version 1403.0.22.14.1, so I did:
    ```bash
    $ curl -LO https://mac.r-project.org/openmp/openmp-15.0.7-darwin20-Release.tar.gz
    $ sudo mkdir -p /opt/R/$(uname -m)
    $ sudo tar -xvf openmp-15.0.7-darwin20-Release.tar.gz --strip-components=2 -C /opt/R/$(uname -m)
    $ rm openmp-15.0.7-darwin20-Release.tar.gz
    ```
    After unpacking, you should find these files on your system:

    ```
    /opt/R/arm64/lib/libomp.dylib
    /opt/R/arm64/include/ompt.h
    /opt/R/arm64/include/omp.h
    /opt/R/arm64/include/omp-tools.h
    ```
4. Add the following lines to `$(HOME)/.R/Makevars`, creating the file if necessary.

    ```
    CPPFLAGS += -Xclang -fopenmp
    LDFLAGS += -lomp
    ```

5. Test that you are able to use R to compile a C or C++ program with OpenMP support while linking relevant libraries from the GNU Fortran installation (indicated by the -l flags in the output of R CMD CONFIG FLIBS).

    The most transparent approach is to use R CMD SHLIB directly. In a temporary directory, create an empty source file omp_test.c and add the following lines:

    ```C
    #ifdef _OPENMP
    # include <omp.h>
    #endif

    #include <Rinternals.h>

    SEXP omp_test(void)
    {
    #ifdef _OPENMP
        Rprintf("OpenMP threads available: %d\n", omp_get_max_threads());
    #else
        Rprintf("OpenMP not supported\n");
    #endif
        return R_NilValue;
    }
    ```
    Compile it:

    ```bash
    $ R CMD SHLIB omp_test.c $(R CMD CONFIG FLIBS)
    ```

    Then call the compiled C function from R:

    ```bash
    $ R -e 'dyn.load("omp_test.so"); invisible(.Call("omp_test"))'
    OpenMP threads available: 8
    ```

    If the compiler or linker throws an error, or if you find that OpenMP is still not supported, then one of us has made a mistake. Please report any issues.

    Note that you can implement the same test using Rcpp, if you don't mind installing it:

    ```R
    library(Rcpp)
    registerPlugin("flibs", Rcpp.plugin.maker(libs = "$(FLIBS)"))
    sourceCpp(code = '
    #ifdef _OPENMP
    # include <omp.h>
    #endif

    #include <Rcpp.h>

    // [[Rcpp::plugins(flibs)]]
    // [[Rcpp::export]]
    void omp_test()
    {
    #ifdef _OPENMP
        Rprintf("OpenMP threads available: %d\\n", omp_get_max_threads());
    #else
        Rprintf("OpenMP not supported\\n");
    #endif
        return;
    }
    ')
    omp_test()
    OpenMP threads available: 8
    ```

# Install OCNet from source
1. Download the OCNet master branch from https://github.com/lucarraro/OCNet
2. Start a new R session and install devtools: 
    ```R
    if (!("devtools" %in% installed.packages())) {install.packages("devtools")}
    ```
3. Install OCNet from the source file
    ```R
    devtools::install_local("path/to/OCNet-master.zip", build_vignettes=TRUE)
    ```

# Install XQuartz
OCNet relies on `rgl` for some 3d visualizations, which is a big issue for apple silicon chip users. While OCNet is properly installed, you won't be able to load it yet. I followed this stackexchange post to solve the issue: https://stackoverflow.com/questions/66011929/package-rgl-in-r-not-loading-in-mac-os/66127391#66127391


1. Uninstall XQuartz by dragging it from the Applications/Utilities folder to the trash (if it's there at all).
2. Uninstall rgl by running `remove.packages("rgl")` in R.
3. Delete those two files named `org.xquartz.startx.plist` from `/Library/LaunchDaemons` and `/Library/LaunchAgents`.
4. Reboot your system to remove the processes started from those files.
5. Reinstall XQuartz from https://www.xquartz.org/
6. Reinstall rgl either from CRAN or from source.

# Run OCNet
run the following command and see if it works
```R
library(OCNet)
set.seed(1)
OCN <- create_OCN(30,20)
draw_simple_OCN(OCN)
```