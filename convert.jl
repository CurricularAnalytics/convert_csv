using CurricularAnalytics
using Glob
using CSV
using DataFrames

function add_course_id(csv_file, folder)
    lines = readlines(open(csv_file))
    if split(lines[1], ",")[1] != "Course_ID"
        f_name = split(csv_file, Base.Filesystem.path_separator)[end]
        open(folder * "/" * f_name, "w") do f
            idx=1
            write(f, "Course_ID,"*lines[1]*"\n")
            for line in lines[2:end-1]
                write_line = string(idx)*","*line*"\n"
                idx +=1
                write(f, write_line)
            end
            write(f, string(idx)*","* lines[end])
        end
    else
        println("Course_id is already added")
    end
end

function read_csv_old(csv_file)
    df = CSV.File(csv_file) |> DataFrame
    c = Dict{String, Course}()
    c_t = Dict{String, Course}()
    for (idx, row) in enumerate(eachrow(df))
        c_Name = row[2]
        c_Credit = row[6]
        if !haskey(c, c_Name)
            c[c_Name] = Course(c_Name, c_Credit; id=idx)
        end
        c_t[c_Name * string(row[1])] = Course(c_Name, c_Credit; id=idx)
    end
    #print(c)
    terms = Array{Term}(undef, nrow(unique(df, :3)))
    by(df, :3) do term 
        termclasses = Array{Course}(undef, nrow(term))
        for (index, row) in enumerate(eachrow(term))
            termclasses[index] = c_t[row[2] * string(row[1])]
            if typeof(row[5]) != Missing
                pre_req = replace(row[5], ", "=>",")
                for req in split(pre_req,",")
                    req = strip(req)
                    if req in keys(c)
                        add_requisite!(c[req], c_t[row[2] * string(row[1])], co)
                    else
                        println("Co-req:\""* req * "\" cannot be found in course list")
                    end
                end
            end 
            if typeof(row[4]) != Missing
                co_req = replace(row[4], ", "=>",")
                for req in split(co_req,",")
                    req = strip(req)
                    if req in keys(c)  
                        add_requisite!(c[req], c_t[row[2] * string(row[1])], pre)
                     else
                        println("Pre-req:\""* req * "\" cannot be found in course list")
                    end
                end
            end   
            
        end
        terms[term[3][1]] = Term(termclasses)  
    end
    c_array = [c_t[i] for i in keys(c_t)]
    #curric = Curriculum("Curric",c_array)
    #complexity(curric)
    return c_array, terms
    #return curric.metrics["complexity"][1]
end

all_universities = glob("*", "original")
for university in all_universities
    university = glob("*", university)
    for csv_filepath in university 
        println(csv_filepath)
        split_path = split(csv_filepath, Base.Filesystem.path_separator)
        if length(split_path) == 3
            add_course_id(csv_filepath, split_path[1] * Base.Filesystem.path_separator * split_path[2] * Base.Filesystem.path_separator)
            c_array, terms = read_csv_old(csv_filepath)
            curric = Curriculum("Curriculum", c_array)
            dp = DegreePlan(split_path[3], curric, terms)
            write_csv(dp, "converted"*Base.Filesystem.path_separator*split_path[2]*Base.Filesystem.path_separator * split_path[3])
        end
    end
end
