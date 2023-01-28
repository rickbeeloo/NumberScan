include("./scanner.jl")
using BenchmarkTools

function gen_test_file(n::Int) 
    bs_file = open("data/test.txt", "w")
    r = rand(Int64, n)
    for x in r 
        print(bs_file, string(x)*"+ ")
    end 
    print(bs_file,"10+\n")
    close(bs_file)
end

function maptest() 
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



function benchmark1() 
    # Generate test data 
    #gen_test_file(100_000)
    f  = "data/test.txt"

    # Some array to store numbers in
    pre = Vector{Int64}(undef, 100_000)

    # Base way of doing this
    j = 1
    @btime for line in eachline($f)
        for item in split(line, " ")
            if isdigit(item[1]) # if first char a number 
                # Skip last char and parse as number
                v = view(item, 1:length(item)-1)
                number = parse(Int64, v)
                $pre[$j] = number
                $j +=1
            end
        end
    end

    j = 1
    @btime for number in mmapScan($f, ' ')
        $pre[$j] = number
        $j +=1
    end
end

function benchmark2() 

    s = "Some test string with 100 and 100 other 40000000000000 numbers"
    x = Vector{UInt8}(s)

    for number in numberScan(x, ' ')
        println(number)
    end

    j = 1
    @btime for item in split($s, " ")
        if isdigit(item[1])
            number = parse(Int64, item)
        end
    end


end

benchmark2()