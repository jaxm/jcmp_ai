class 'MeshTriangle'

function MeshTriangle:__init( position, size )
	self.angle = Angle()
	self.a = position + self.angle * Vector3( 0, 0, 0 )
	self.b = position + self.angle * Vector3( -size, 0, -size )
	self.c = position + self.angle * Vector3( size, 0, -size )
	self.forward_multi = 5
	self.width_multi = 1.5
	self.size = size
	self.position = position
	local a,b,c = self.a, self.b, self.c

	self.centerPoint = self:GetCenterPoint( self.a, self.b, self.c )

	self.colour = Color.Blue

  	self.debugPoints = {}
  	self.debugLines = {}

  	return self
end

function MeshTriangle:SetPosition( position )
	self.position = position
	local forward_multi = self.forward_multi
	local width_multi = self.width_multi
	local size = self.size
	self.a = position + self.angle * Vector3( 0, 0, 0 )
	self.b = position + self.angle * Vector3( -size*width_multi, 0, -size*forward_multi )
	self.c = position + self.angle * Vector3( size*width_multi, 0, -size*forward_multi )
	self.centerPoint = self:GetCenterPoint( self.a, self.b, self.c )
end

function MeshTriangle:SetAngle( angle )
	self.angle = angle
	local forward_multi = self.forward_multi
	local width_multi = self.width_multi
	local size = self.size
	self.a = self.position + angle * Vector3( 0, 0, 0 )
	self.b = self.position + angle * Vector3( -size*width_multi, 0, -size*forward_multi )
	self.c = self.position + angle * Vector3( size*width_multi, 0, -size*forward_multi )
	self.centerPoint = self:GetCenterPoint( self.a, self.b, self.c )
end

function MeshTriangle:UpdatePositionAndAngle( position, angle )
	self.angle = angle
	self.position = position
	local size = self.size
	local forward_multi = self.forward_multi
	local width_multi = self.width_multi
	self.a = position + angle * Vector3( 0, 0, 0 )
	self.b = position + angle * Vector3( -size*width_multi, 0, -size*forward_multi )
	self.c = position + angle * Vector3( size*width_multi, 0, -size*forward_multi )
	self.centerPoint = self:GetCenterPoint( self.a, self.b, self.c )
end

function MeshTriangle:Draw()
	-- if not self.model then return end
	-- draw triangle fill
	-- self.model:Draw()
	-- draw triangle points
	local t = { self.a, self.b, self.c }
	local last_point = nil
	for i=1,#t do
		local point = t[i]
		if last_point then
			Render:DrawLine( point, last_point, self.colour )
		else
			Render:DrawLine( point, t[#t], self.colour )
		end
		last_point = point
	end
end

function MeshTriangle:GetLoS( a, b )
	a = a + Vector3(0, .1, 0)
	b = b + Vector3(0, .1, 0)
	local distance = a:Distance(b)
	local ray = Physics:Raycast( a, (b - a):Normalized(), 0, distance  )
	if math.abs(ray.distance - distance) > 1 then
		return false, ray
	end

	return true, ray 
end

function MeshTriangle:IsPointInside( p )
	-- local a, b, c = self.a, self.b, self.c
	-- if self:SameSide( p, a, b, c ) and self:SameSide( p, b, a, c ) and self:SameSide( p, c, a, b ) then
	-- 	return true
	-- else
	-- 	return false
	-- end
	return self:BarycentricPointInside( p )
end

function MeshTriangle:BarycentricPointInside( p )
	local a, b, c = self.a, self.b, self.c
	-- compute vectors
	local v0 = c - a
	local v1 = b - a
	local v2 = p - a

	-- compute dot products
	local dot00 = v0:Dot(v0)
	local dot01 = v0:Dot(v1)
	local dot02 = v0:Dot(v2)
	local dot11 = v1:Dot(v1)
	local dot12 = v1:Dot(v2)

	-- compute barycentric coordinates
	local invDenom = 1 / ( dot00 * dot11 - dot01 * dot01 )
	local u = ( dot11 * dot02 - dot01 * dot12 ) * invDenom
	local v = ( dot00 * dot12 - dot01 * dot02 ) * invDenom

	-- check if the point is inside triangle
	return ( u >= 0 ) and ( v >= 0 ) and ( u + v < 1 ) or false
end

function MeshTriangle:SameSide( p1, p2, a, b )
	local cp1 = ( b - a ):Cross( p1 - a )
	local cp2 = ( b - a ):Cross( p2 - a )
	local dot = cp1:Dot( cp2 ) 
	if dot >= 0 then 
		return true
	else
		return false
	end
end

function MeshTriangle:GetCenterPoint( a, b, c )
	return (a + b + c) / 3
end

local list = {}
count = 0

function AddTriangle( position, size )
	local newTriangle = MeshTriangle( position, size )
	table.insert( list, newTriangle )
	return newTriangle
end

function RemoveTriangle( tri )
	for i=1, #list do
		local triangle = list[i]
		if triangle == tri then
			table.remove( list, i )
			break
		end
	end
end