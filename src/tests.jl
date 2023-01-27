include("./scanner.jl")
using BenchmarkTools

function maptest() 
    bs_file = open("data/test.txt", "w")
    r = rand(Int64, 5)
    for x in r 
        print(bs_file, string(x)*"+ ")
    end 
    print(bs_file,"10+\n")
    close(bs_file)

    for parsed_number in mmapScan("data/test.txt", ' ')
        println(parsed_number)
    end
end

function shortTest() 
    x = Vector{UInt8}("100+ 200- 400+? 800&")  
    for number in numberScan(x, ' ')
        println(number)
    end
end

shortTest()