using CurricularAnalytics
using Glob
using CSV
using DataFrames

function add_course_id(csv_file,tier)
    lines = readlines(open(csv_file))
    f_name = split(csv_file,Base.Filesystem.path_separator)[end]
    open(tier*"/"*f_name, "w") do f
        idx=1
        write(f, "Course_ID,"*lines[1]*"\n")
        for line in lines[2:end-1]
            write_line = string(idx)*","*line*"\n"
            idx +=1
            write(f, write_line)
        end
        write(f, string(idx)*","* lines[end])
    end
end

for tier in ["Tier1","Tier2","Tier3"]
    tier1files = glob("*","Old_Tier_Files/"*tier)
    for csv_filepath in tier1files
        println(csv_filepath)
        add_course_id(csv_filepath,tier)
    end
end

function read_csv_old(csv_file)
    df = CSV.File(csv_file) |> DataFrame
    c= Dict{String, Course}()
    c_t= Dict{String, Course}()
    for (idx, row) in enumerate(eachrow(df))
        c_Name = row[2]
        c_Credit = row[6]
        if !haskey(c,c_Name)
            c[c_Name] = Course(c_Name, c_Credit; id=idx)
        end
        c_t[c_Name*string(row[1])] = Course(c_Name, c_Credit; id= idx)
    end
    #print(c)
    terms = Array{Term}(undef, nrow(unique(df, :3)))
    by(df, :3) do term 
        termclasses = Array{Course}(undef,nrow(term))
        for (index, row) in enumerate(eachrow(term))
            termclasses[index]=c_t[row[2]*string(row[1])]
            if typeof(row[5]) != Missing
                try
                    for req in split(row[5],", ")
                        add_requisite!(c[req],c_t[row[2]*string(row[1])],co)
                    end
                catch
                    for req in split(row[5],",")
                        add_requisite!(c[req],c_t[row[2]*string(row[1])],co)
                    end
                end
            end 
            if typeof(row[4]) != Missing
                try
                    for req in split(row[4],", ")
                        #println(req)
                        add_requisite!(c[req],c_t[row[2]*string(row[1])],pre)
                    end
                catch
                    for req in split(row[4],",")
                        #println(req)
                        add_requisite!(c[req],c_t[row[2]*string(row[1])],pre)
                    end
                end
                
            end   
            
        end
        terms[term[3][1]]=Term(termclasses)  
    end
    c_array= [c_t[i] for i in keys(c_t)]
    #curric = Curriculum("Curric",c_array)
    #complexity(curric)
    return c_array, terms
    #return curric.metrics["complexity"][1]
end

tier1files = glob("*","Tier1")
for csv_filepath in tier1files
    println(csv_filepath)
    f_name = split(csv_filepath,Base.Filesystem.path_separator)[end]
    c_array, terms = read_csv_old(csv_filepath)
    curric = Curriculum("Curriculum",c_array)
    dp = DegreePlan(f_name, curric, terms)
    write_csv(dp, "Tier1/"*f_name)
end

tier1files = glob("*","Tier2")
for csv_filepath in tier1files
    println(csv_filepath)
    f_name = split(csv_filepath,Base.Filesystem.path_separator)[end]
    c_array, terms = read_csv_old(csv_filepath)
    curric = Curriculum("Curriculum",c_array)
    dp = DegreePlan(f_name, curric, terms)
    write_csv(dp, "Tier2/"*f_name)
end

tier1files = glob("*","Tier3")
for csv_filepath in tier1files
    println(csv_filepath)
    f_name = split(csv_filepath,Base.Filesystem.path_separator)[end]
    c_array, terms = read_csv_old(csv_filepath)
    curric = Curriculum("Curriculum",c_array)
    dp = DegreePlan(f_name, curric, terms)
    write_csv(dp, "Tier3/"*f_name)
end

csv_filepath = "Tier2/University of Alabama.csv"
f_name = split(csv_filepath,Base.Filesystem.path_separator)[end]
c_array, terms = read_csv_old(csv_filepath)
curric = Curriculum("Curriculum",c_array)
dp = DegreePlan(f_name, curric, terms)
write_csv(dp, "Tier2/"*f_name)

csv_filepath = "Tier2/Southern Methodist University.csv"
f_name = split(csv_filepath,Base.Filesystem.path_separator)[end]
c_array, terms = read_csv_old(csv_filepath)
curric = Curriculum("Curriculum",c_array)
dp = DegreePlan(f_name, curric, terms)
write_csv(dp, "Tier2/"*f_name)
