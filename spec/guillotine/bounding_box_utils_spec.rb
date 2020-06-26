require "spec_helper"

RSpec.describe Guillotine::BoundingBoxUtils do
  let(:utils) { described_class }

  let(:aabb) do
    {
      "min": [2, 2],
      "max": [5, 5]
    }
  end

  let(:aabb_edges) do
    [
      [[2, 2], [2, 5]],
      [[2, 5], [5, 5]],
      [[5, 5], [5, 2]],
      [[5, 2], [2, 2]]
    ]
  end

  describe "#vertex_in_aabb?" do
    let(:inside) do
      vertexes.map { |vertex| utils.vertex_in_aabb?(aabb, vertex) }
    end

    context "when the vertex is inside the box" do
      let(:vertexes) do
        [
          [3, 3],
          [2.001, 2],
          [4.9999, 2],
          [4, 4]
        ]
      end

      it "returns true" do
        expect(inside).to eq [true, true, true, true]
      end
    end

    context "when the vertex is inside an edge" do
      let(:vertexes) do
        [
          [2, 4],
          [4, 2],
          [4, 5],
          [5, 4]
        ]
      end

      it "returns true" do
        expect(inside).to eq [true, true, true, true]
      end
    end

    context "when the vertex is inside a box vertex" do
      let(:vertexes) do
        [
          [2, 2],
          [2, 5],
          [5, 5],
          [5, 2]
        ]
      end

      it "returns true" do
        expect(inside).to eq [true, true, true, true]
      end
    end

    context "when the vertex is outside the box" do
      let(:vertexes) do
        [
          [0, 0],
          [0, 4],
          [0, 6],
          [4, 6],
          [6, 6],
          [6, 4],
          [6, 0],
          [4, 0]
        ]
      end

      it "returns true" do
        expect(inside).to eq [false, false, false, false, false, false, false, false]
      end
    end
  end

  describe "#edges_touch?" do
    let(:any_touch) do
      edges.map do |edge|
        aabb_edges.select { |aabb_edge| utils.edges_touch?(edge, aabb_edge) }.count
      end
    end

    let(:inverted_any_touch) do
      edges.map do |edge|
        aabb_edges.select { |aabb_edge| utils.edges_touch?(aabb_edge, edge) }.count
      end
    end

    let(:edges) do
      [
        # one edge collision
        [[3, 3], [3, 6]],
        [[3, 3], [6, 3]],
        [[3, 3], [3, 1]],
        [[3, 3], [1, 3]],
        # opposite edge collision
        [[3, 6], [3, 1]],
        [[6, 3], [1, 3]],
        # edge overlaps
        [[1, 2], [6, 2]],
        [[1, 5], [6, 5]],
        [[2, 1], [2, 6]],
        [[5, 1], [5, 6]],
        # adjacent edge collision
        [[1, 3.5], [3.5, 1]],
        [[3.5, 1], [6, 3.5]],
        [[6, 3.5], [3.5, 6]],
        [[3.5, 6], [1, 3.5]],
        # diagonals
        [[1, 1], [6, 6]],
        [[1, 6], [6, 1]]
      ]
    end

    it "return true for edges touching and false otherwise" do
      expect(any_touch).to eq [1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 4, 4]
    end

    it "works simetric" do
      expect(any_touch).to eq inverted_any_touch
    end
  end

  describe "#collides?" do
    let(:collide) do
      utils.collides?(aabb, box)
    end

    context "when vertex is inside the box" do
      let(:box) do
        [
          [4, 4],
          [6, 4],
          [6, 6],
          [4, 6]
        ]
      end

      it "retruns true" do
        expect(collide).to eq true
      end
    end

    context "when some edge collides" do
      let(:box) do
        [
          [4, 1],
          [6, 1],
          [6, 6],
          [4, 6]
        ]
      end

      it "retruns true" do
        expect(collide).to eq true
      end
    end

    context "when all word vertexes are inside the bounding box" do
      let(:box) do
        [
          [1, 1],
          [6, 1],
          [6, 6],
          [1, 6]
        ]
      end

      it "retruns false" do
        expect(collide).to eq false
      end
    end

    context "when the tho boxes don't collide" do
      let(:box) do
        [
          [4, 7],
          [6, 7],
          [6, 8],
          [4, 8]
        ]
      end

      it "retruns true" do
        expect(collide).to eq false
      end
    end
  end
end
