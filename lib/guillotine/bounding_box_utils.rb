module Guillotine
  module BoundingBoxUtils
    extend self

    def vertex_in_aabb?(aabb, vertex)
      return false if vertex[0] < aabb[:min][0]
      return false if vertex[0] > aabb[:max][0]
      return false if vertex[1] < aabb[:min][1]
      return false if vertex[1] > aabb[:max][1]

      true
    end

    def edges_touch?(edge1, edge2) # rubocop:disable AbcSize, MethodLength
      ax = edge1[0][0].to_f
      ay = edge1[0][1].to_f
      bx = edge1[1][0].to_f
      by = edge1[1][1].to_f

      cx = edge2[0][0].to_f
      cy = edge2[0][1].to_f
      dx = edge2[1][0].to_f
      dy = edge2[1][1].to_f

      return false if ((cx - dx) * (ay - by) - (cy - dy) * (ax - bx)).zero?

      alpha_numerator = (by - dy) * (cx - dx) - (bx - dx) * (cy - dy)
      alpha = alpha_numerator / ((ax - bx) * (cy - dy) - (ay - by) * (cx - dx))
      beta_numerator = (dy - by) * (ax - bx) - (dx - bx) * (ay - by)
      beta = beta_numerator / ((cx - dx) * (ay - by) - (cy - dy) * (ax - bx))

      return false if alpha.negative? || alpha > 1
      return false if beta.negative? || beta > 1

      true
    end

    def collides?(aabb, box) # rubocop:disable AbcSize
      # Checks if one point of the box is inside the aabb or if edges touch
      # Ignores case when aabb is inside box since is highly unprobable

      box.each { |vertex| return true if vertex_in_aabb?(aabb, vertex) }

      box.each_index do |vertex1|
        vertex2 = (vertex1 + 1) % 4
        edge1 = [box[vertex1], box[vertex2]]

        edge2 = [aabb[:min], [aabb[:min][0], aabb[:max][1]]]
        return true if edges_touch?(edge1, edge2)

        edge2 = [aabb[:min], [aabb[:max][0], aabb[:min][1]]]
        return true if edges_touch?(edge1, edge2)

        edge2 = [aabb[:max], [aabb[:max][0], aabb[:min][1]]]
        return true if edges_touch?(edge1, edge2)

        edge2 = [aabb[:max], [aabb[:min][0], aabb[:max][1]]]
        return true if edges_touch?(edge1, edge2)
      end

      false
    end
  end
end
