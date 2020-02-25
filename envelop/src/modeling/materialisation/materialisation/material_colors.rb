require_relative '../../../vendor/rb/color_math'

module Envelop
  module Materialisation
    DEFAULT_ALPHA = 0.75
    MAX_DEVIATION = 0.3 # TODO: consider if these values are optimal
    MIN_DEVIATION = 0.1
    MAX_HUE_DEVIATION = 0.1
    MIN_HUE_DEVIATION = 0.01
    MIN_HSL_S = 20
    MAX_HSL_S = 100
    MIN_HSL_L = 20
    MAX_HSL_L = 90

    def self.random_color()
      res = ColorMath.from_hsl(
        rand(0..360),
        rand(MIN_HSL_S..MAX_HSL_S),
        rand(MIN_HSL_L..MAX_HSL_L)
      )

      res
    end

    def self.deviate_color(color_hsl)
      return nil if color_hsl.nil?

      rand_hue = [-1, 1].sample * rand(MIN_HUE_DEVIATION..MAX_HUE_DEVIATION) * 360
      rand1 = [-1, 1].sample * rand(MIN_DEVIATION..MAX_DEVIATION) * 100
      rand2 = [-1, 1].sample * rand(MIN_DEVIATION..MAX_DEVIATION) * 100

      res = ColorMath.from_hsl(
        (color_hsl[0] + rand_hue).clamp(0, 360),
        (color_hsl[1] + rand1).clamp(MIN_HSL_S, MAX_HSL_S),
        (color_hsl[2] + rand2).clamp(MIN_HSL_L, MAX_HSL_L)
      )

      res
    end
  end
end
