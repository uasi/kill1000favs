def files
  Regexp.union(
    %r{app\.rb},
    %r{config\.ru},
    %r{views/.*\.slim},
  )
end

watch(files) { system('touch tmp/restart.txt') }
