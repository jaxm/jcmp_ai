sin = math.sin
rad = math.rad
deg = math.deg
acos = math.acos
min = math.min
abs = math.abs
floor = math.floor
ceil = math.ceil
sqrt = math.sqrt
random = math.random
tGetMS = Timer.GetMilliseconds

Angle.NormalisedDir = function(a1, a2)
	return (a1 - a2):Normalized()
end

Angle.RotateToward = function(q1, q2, max_ang)
	local num = Angle.Delta(q1, q2)
	if num == 0 then
		return q2
	end

	t = math.min(1, (max_ang / num))

	return Angle.Slerp(q1, q2, t)
end

Angle.ToAngleAxis = function(q)
    local sqrLen = q.x*q.x + q.y*q.y + q.z*q.z
    
    local angle = 0
    local axis = Vector3(1, 0, 0)
    
    if sqrLen > 0 then
        angle = 2 * math.acos(q.w)
        axis = Vector3(q.x, q.y, q.z):Normalized()
    end
    
    return angle, axis
end

Vector3.Scale = function( v1, v2 )
	return Vector3( v1.x*v2.x, v1.y*v2.y, v1.z*v2.z )
end

function DegreesDifference(theta1, theta2)
    return (theta2 - theta1 + 180) % 360 - 180
end

function OppositeDegrees(theta)
    return (theta + 180) % 360
end

function YawToHeading(yaw)
    if yaw < 0 then
        return -yaw
    else
        return 360 - yaw
    end
end

function HeadingToYaw(heading)
    if heading < 180 then
        return -heading
    else
        return 360 - heading
    end
end

function Vehicle:GetRoll()
    return math.deg(self:GetAngle().roll)
end

function Vehicle:GetPitch()
    return math.deg(self:GetAngle().pitch)
end

function Vehicle:GetYaw()
    return math.deg(self:GetAngle().yaw)
end

function Vehicle:GetHeading()
    local yaw = self:GetYaw()
    return YawToHeading(yaw)
end

function round(x) 
    if x<0 then return -round(-x) end 
    return  math.floor(x+0.5) 
end 