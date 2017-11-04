
class Chef
  class Recipe
    
    def puts! args, label=""
      puts "+++ +++ #{label}"
      puts args.inspect
    end

  end
end
