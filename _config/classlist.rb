def classList(rootpath)
    glob_str = rootpath + "**/*.as"
    Dir.glob(glob_str) do |filename| 
      puts filename.sub(rootpath,'').gsub('/','.').gsub('.as','')
    end
end

classList("../src/")