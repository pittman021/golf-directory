class TagEmojiService
  TAG_EMOJIS = {
    'golf:top100' => '🎖️',
    'golf:championship' => '🏆',
    'golf:resort' => '⛳',
    'golf:links' => '🌊',
    'golf:parkland' => '🌳',
    'golf:desert' => '🏜️',
    'golf:mountain' => '⛰️'
  }.freeze

  def self.emoji_for(tag)
    TAG_EMOJIS[tag] || '🏷️'
  end
end 