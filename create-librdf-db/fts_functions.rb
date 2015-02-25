def divide_value(whole)
  divisions = whole.split(' ').map { |word|
    divide(word)
  }
  divisions.flatten!
  divisions.uniq!

  divisions.join(' ')
end

def divide(word)
  suffix = ""
  word.reverse!.chars.reduce([]) { |subdivisions, char|
    suffix.prepend(char)
    subdivisions << suffix.dup
  }
end
