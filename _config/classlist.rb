def classList(rootpath)
    glob_str = rootpath + "**/*.as"
    Dir.glob(glob_str) do |filename| 
      puts filename.sub(rootpath,'').gsub('/','.')
    end
end

classList("../src/")