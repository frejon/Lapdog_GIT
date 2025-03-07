%
% Conditionally modify a LBL column description struct to include a MISSING_CONSTANT.
% Having this function simplifies createLBL.
%
%
% ARGUMENTS AND RETURN VALUES
% ===========================
% addMissingConstant    : True/false for whether oc should me modified or not.
% oc                    : Struct describing LBL column with field .DESCRIPTION (which might be modified) and to which
%                         .MISSING_CONSTANT might be added. OC = "OBJECT=COLUMN"
% descriptionAmendement : String which is added to the end of DESCRIPTION (after adding one whitespace).
% missingConstant       : MISSING_CONSTANT value.
%
%
% Initially created 2018-04-10 by Erik P G Johansson, IRF Uppsala.
%
function oc = optionally_add_MISSING_CONSTANT(addMissingConstant, missingConstant, oc, descriptionAmendment)
    % PROPOSAL: Move into createLBL.definitions.
    
    % ASSERTION
    % IMPLEMENTATION NOTE: Assertion here to guard against caller confusing arguments with each other.
    if ~(islogical(addMissingConstant) || ismember(addMissingConstant, [0,1]))
        error('addMissingConstant=%g not true/false or 0/1.', addMissingConstant)
    end    
    
    if addMissingConstant        
        % ASSERTION: Make sure previous DESCRIPTION text ends properly so that a continuation can be added.
        if oc.DESCRIPTION(end) ~= '.'
            error('Preexisting un-amended DESCRIPTION does not end with period.')
        end
        
        oc.DESCRIPTION      = [oc.DESCRIPTION, ' ', descriptionAmendment];
        oc.MISSING_CONSTANT = missingConstant;
    end
end
