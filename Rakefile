require 'find'

TYPES = ['program', 'variables', 'operations', 'workflow']

desc "Generate dot diagrams of all types for specified script"
task :dot, [:script] do |t, args|
  TYPES.each do |type|
    ruby "workflow.rb #{args.script} #{type} > #{args.script[0...-3]}-#{type}.dot"
  end
end

desc "Generate eps diagrams of all types and yaml for specified script"
task :draw, [:script] do |t, args|
  TYPES.each do |type|
    ruby "workflow.rb #{args.script} #{type} | dot -Tpng -o #{args.script[0...-3]}-#{type}.png"
  end
  ruby "workflow.rb #{args.script} yaml > #{args.script[0...-3]}.yaml"
end

desc "Invokes draw task for all .rb files recursively"
task :walk, [:path] do |t, args|
  Find.find(args.path) do |f|
    if File.file?(f) and f.end_with?(".rb")
      puts "processing ... #{f}"
      Rake::Task[:draw].execute Rake::TaskArguments.new [:script], [f]
    end
  end
end

desc "Generate internal representation"
task :program, [:script] do |t, args|
  ruby "workflow.rb #{args.script} program > #{args.script[0...-3]}-program.dot"
end

desc "Make workflow diagram for specified script"
task :workflow, [:script] do |t, args|
  ruby "workflow.rb #{args.script} workflow"
end

desc "Generate variable dependencies graph"
task :variables, [:script] do |t, args|
  ruby "workflow.rb #{args.script} variables > #{args.script[0...-3]}-variables.dot"
end

desc "Generate operations dependencies graph"
task :operations, [:script] do |t, args|
  ruby "workflow.rb #{args.script} operations > #{args.script[0...-3]}-operations.dot"
end

desc "Generate s-expression for specified script"
task :sexp, [:script] do |t, args|
  ruby "workflow.rb #{args.script} sexp > #{args.script[0...-3]}.sexp"
end

desc "Generage doc"
task :documentation do
  sh "rdoc -o doc --inline-source --format=html -T hanna lib/*.rb"
end

desc "Remove all gif and dot files"
task :clean do
  ["eps", "gif", "png", "dot", "yaml"].each do |ext|
    sh "rm -f test-scripts/*.#{ext}"
    sh "rm -f patterns/*.#{ext}"
  end
end
