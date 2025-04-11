class String
  def similarity(other)
    return 1.0 if self == other
    return 0.0 if self.empty? || other.empty?

    # Convert to arrays of characters
    a = self.chars
    b = other.chars

    # Calculate Levenshtein distance
    n = a.length
    m = b.length
    return 0.0 if n == 0 || m == 0

    # Create distance matrix
    d = Array.new(n + 1) { Array.new(m + 1) }
    (0..n).each { |i| d[i][0] = i }
    (0..m).each { |j| d[0][j] = j }

    # Fill in the distance matrix
    (1..n).each do |i|
      (1..m).each do |j|
        cost = (a[i - 1] == b[j - 1]) ? 0 : 1
        d[i][j] = [d[i - 1][j] + 1,     # deletion
                   d[i][j - 1] + 1,     # insertion
                   d[i - 1][j - 1] + cost].min  # substitution
      end
    end

    # Calculate similarity ratio
    max_length = [n, m].max
    similarity = 1.0 - (d[n][m].to_f / max_length)
    similarity
  end
end 