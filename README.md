## Numby - Int scan over contaminated bytes
Just for own usage now as this is not developed at all. I use C's [memchr](https://cplusplus.com/reference/cstring/memchr/ "memchr") to search a byte block for a specific byte. In this case a delimiter. This is similar to [findfirst](https://github.com/JuliaLang/julia/blob/master/base/strings/search.jl#L15 "findfirst"), but then without safety checks for speed.  Then we can give our best shot to extract the integer using C's[ atoi](https://cplusplus.com/reference/cstdlib/atoi/?kw=atoi " atoi"). Unlike Julias base parse this can deal with messy "strings" (actually bytes) like "300++" or "+300messy". The risk however is that there is [no error checking](https://stackoverflow.com/a/46090749/7885426) at all, so you can only use this if you exactly know what your input looks like.

This is around 2x faster when parsing numbers from a file and 5x faster when parsing from an existing `UInt8` vector (see [benchmark scripts](https://github.com/rickbeeloo/NumberScan/blob/master/src/tests.jl))

`add https://github.com/rickbeeloo/NumberScan`

**Note**
- atoi will return `0` if it cannot parse the number. So when interested in `0` this is useless.
- no safety checks are performed, if you use this make sure to test it
- if you want to parse an integer from a messy string you can also just call `NumberScan._atoi`.

------------

### numberScan
We will use this to quickly parse numbers from the [GFA](http://gfa-spec.github.io/GFA-spec/GFA1.html "GFA") format. So for example:

```Julia
 x = Vector{UInt8}("100+ 200- 400+ 800-")  
 for number in numberScan(x, ' ')
        println(number)
 end
```

### mmapScan
Since files are also just byte blocks we can `Mmap` files and scan them for numbers
```Julia
targets = Set([100, 200, 300, 1000])
    found = 0
    for number in mmapScan("data/test.txt", ' ')
        if number in $targets 
            found +=1
        end
    end
    println(found)
```

---
### TODO
- Make this more general, like keep iterating till numbers are found. Such that you don't have to check for `number != 0`. Perhaps also make this work without delimiter
- Maybe some basic saftey checks
- Could use unsafe type conversion of the pointers to not have any error instructions in the native code
