----------------------------------------------------------------------------
-- This script hooks onto some duplicator functions and adds parenting
-- support to the vanilla Duplicator tool (compatible with Adv. Dupe 2).
----------------------------------------------------------------------------

util.AddNetworkString( "MultiParent_SendNotification" )

if game.SinglePlayer() then
	util.AddNetworkString( "MultiParent_CleanupClientVisuals" )
end

duplicator.OriginalGetAllConstrainedEntitiesAndConstraints = duplicator.OriginalGetAllConstrainedEntitiesAndConstraints or duplicator.GetAllConstrainedEntitiesAndConstraints
duplicator.OriginalPaste = duplicator.OriginalPaste or duplicator.Paste
duplicator.OriginalCopyEntTable = duplicator.OriginalCopyEntTable or duplicator.CopyEntTable

function duplicator.GetAllConstrainedEntitiesAndConstraints( ent, entTable, constraintTable )
	local entValid = IsValid( ent )
	if entValid and entTable[ent:EntIndex()] then return end

	entTable, constraintTable = duplicator.OriginalGetAllConstrainedEntitiesAndConstraints( ent, entTable, constraintTable ) or entTable, constraintTable

	if not entValid and not ent:IsWorld() then return end

	local parent = ent:GetParent()

	if IsValid( parent ) then
		duplicator.GetAllConstrainedEntitiesAndConstraints( parent, entTable, constraintTable )
	end

	for _, child in pairs( ent:GetChildren() ) do
		duplicator.GetAllConstrainedEntitiesAndConstraints( child, entTable, constraintTable )
	end

	return entTable, constraintTable
end

function duplicator.Paste( ply, entityList, constraintList )
	local createdEntities, createdConstraints = duplicator.OriginalPaste( ply, entityList, constraintList )

	for entID, ent in pairs( createdEntities ) do
		local dupeInfo = entityList[entID].BuildDupeInfo

		if dupeInfo and dupeInfo.DupeParentID then
			ent:SetParent( createdEntities[dupeInfo.DupeParentID] )
		end
	end

	return createdEntities, createdConstraints
end

function duplicator.CopyEntTable( ent )
	local output = duplicator.OriginalCopyEntTable( ent )
	local parent = ent:GetParent()

	if IsValid( parent ) then
		if not output.BuildDupeInfo or isfunction( output.BuildDupeInfo ) then
			output.BuildDupeInfo = {}
		end

		output.BuildDupeInfo.DupeParentID = parent:EntIndex()
	end

	return output
end