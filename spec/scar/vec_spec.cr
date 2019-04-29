require "../spec_helper"

include Scar

# Float accuracy
FAC = 1.0e-5

describe Vec do
  describe "#from" do
    it "creates a Vec instance from a SFML Vector or a Chipmunk Vector" do
      Vec.from(SF::Vector2.new(2.5, 163.125)).should eq Vec.new(2.5, 163.125)
    end
  end

  describe "#+" do
    it "adds two Vectors together" do
      (Vec.new(2, 1.6) + Vec.new(5.2, 3)).should be_close Vec.new(7.2, 4.6), FAC
    end
  end

  describe "#-" do
    it "substracts one Vector from another" do
      (Vec.new(2, 1.6) - Vec.new(5.2, 3)).should be_close Vec.new(-3.2, -1.4), FAC
    end
  end

  describe "#*" do
    it "does component wise multiplication of two Vectors or scaling of one Vector by a scalar" do
      (Vec.new(3, 4.1) * Vec.new(3.2, 2)).should be_close Vec.new(9.6, 8.2), FAC

      (Vec.new(3, 4.1) * 5).should be_close Vec.new(15, 20.5), FAC
      (Vec.new(3, 4.1) * 2.5).should be_close Vec.new(7.5, 10.25), FAC
    end
  end

  describe "#/" do
    it "does component wise division of two Vectors or inverse scaling of one Vector by a scalar" do
      (Vec.new(3, 4.1) / Vec.new(3.2, 2)).should be_close Vec.new(0.9375, 2.05), FAC

      (Vec.new(3, 4.1) / 5).should be_close Vec.new(0.6, 0.82), FAC
      (Vec.new(3, 4.1) / 2.5).should be_close Vec.new(1.2, 1.64), FAC
    end
  end

  describe "#manhattan" do
    it "returns the manhattan distance of the vector (basically adds x and y)" do
      Vec.new(3, 2.6).manhattan.should be_close 5.6, FAC
      Vec.new(2.4, -1).manhattan.should be_close 3.4, FAC
    end
  end

  describe "#abs" do
    it "returns a vector with both x and y abs-ed" do
      Vec.new(-3.2, -5.1432).abs.should be_close Vec.new(3.2, 5.1432), FAC
    end
  end

  describe "#dot" do
    it "returns dot product" do
      Vec.new(2.5, -3.21).dot(Vec.new(-3.3, 6.32)).should be_close -(71343f32/2500f32), FAC
    end
  end

  describe "#cross" do
    it "returns cross product" do
      Vec.new(2.5, -3.21).cross(Vec.new(-3.3, 6.32)).should be_close 5.207, FAC
    end
  end

  describe "#length" do
    it "returns the length of the vector" do
      Vec.new(1, 1).length.should be_close Math.sqrt(2), FAC
      Vec.new(-5, -5).length.should be_close Math.sqrt(50), FAC
      Vec.new(4.4, 5.2).length.should be_close Math.sqrt(46.4), FAC
    end
  end

  describe "#length_squared" do
    it "returns the squared length of the vector" do
      Vec.new(1, 1).length_squared.should be_close 2, FAC
      Vec.new(-5, -5).length_squared.should be_close 50, FAC
      Vec.new(4.4, 5.2).length_squared.should be_close 46.4, FAC
    end
  end

  describe "#unit" do
    it "normalizes the vector to length one" do
      Vec.new(7, 2).unit.should be_close Vec.new(7f32/Math.sqrt(53), 2f32/Math.sqrt(53)), FAC
      Vec.new(-2.3, -1.9).unit.should be_close Vec.new(-0.770962, -0.636881), FAC
      Vec.new(8234.23e10, 364.2).unit.should be_close Vec.new(1, 4.423e-12), FAC
    end
  end

  describe "#rotate" do
    it "rotates the vector by a given angle" do
      Vec.new(2.53, 1.223).rotate(2).should be_close Vec.new(-2.164922, 1.791575), FAC
      Vec.new(2.53, 1.223).rotate(Math::PI / 4).should be_close Vec.new(0.924189, 2.653772), FAC
    end
  end

  describe "#angle" do
    it "returns the angle to the x-axis" do
      Vec.new(5.42, 9.11).angle.should be_close 1.0340979, FAC
    end
  end

  describe "#angle_to" do
    it "returns between two vectors" do
      Vec.new(3.33, 6.89).angle_to(Vec.new(1.92, 3.74)).should be_close -0.0240795, FAC
    end
  end

  describe "#new_x" do
    it "returns the same vector but with a new x value" do
      Vec.new(2, 5432).new_x(1.443).should be_close Vec.new(1.443, 5432), FAC
    end
  end

  describe "#new_y" do
    it "returns the same vector but with a new y value" do
      Vec.new(1, 552).new_y(2.3).should be_close Vec.new(1, 2.3), FAC
    end
  end

  describe "#sf" do
    it "returns the vector as an SF::Vector2f" do
      Vec.new(5.43, 6.78).sf.should eq SF::Vector2.new(5.43f32, 6.78f32)
    end
  end
end
