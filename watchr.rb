def files
  Regexp.union(
    %r{app\.rb},
    %r{views/.*\.slim},
  )
end

watch(files) { system('touch tmp/restart.txt') }
