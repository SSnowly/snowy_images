local BASE_IMAGE_PATH = GetResourcePath(GetCurrentResourceName()) .. "/images/"
local OX_INV_IMAGE_PATH = GetResourcePath("ox_inventory") .. "/web/images/"
local Config = require 'config'

lib.print.info("Base image path: ^7" .. BASE_IMAGE_PATH)

-- Function to delete all PNG files in a directory
local function deleteAllPngFiles(directory)
    lib.print.warn("Starting deletion of PNG files in: ^7" .. directory)
    local handle = io.popen('dir "' .. directory .. '" /b /a-d')
    if not handle then
        lib.print.error("Failed to read directory for deletion")
        return false
    end
    
    local filesDeleted = 0
    
    for file in handle:lines() do
        if file:match("%.png$") then
            local fullPath = directory .. file
            local success = os.remove(fullPath)
            if success then
                lib.print.info("Deleted: ^7" .. file)
                filesDeleted = filesDeleted + 1
            else
                lib.print.error("Failed to delete: ^7" .. file)
            end
        end
    end
    
    handle:close()
    lib.print.info(string.format("Deletion complete. Removed %d files", filesDeleted))
    return true
end

-- Function to copy a file from source to destination
local function copyFile(source, dest)
    local sourceFile = io.open(source, "rb")
    if not sourceFile then
        lib.print.error("Failed to open source file: ^7" .. source)
        return false
    end
    
    local destFile = io.open(dest, "wb")
    if not destFile then
        sourceFile:close()
        lib.print.error("Failed to create destination file: ^7" .. dest)
        return false
    end
    
    local content = sourceFile:read("*all")
    destFile:write(content)
    
    sourceFile:close()
    destFile:close()
    return true
end

-- Function to copy all PNG files from source directory and its subdirectories
local function copyAllPngFiles()
    if not Config.GenerateOnScriptStart then
        lib.print.info("Image generation disabled in config")
        return
    end

    -- Force delete existing images if configured
    if Config.ForceDeleteImagesBeforeReplicating then
        lib.print.warn("Force delete enabled, removing existing images...")
        if not deleteAllPngFiles(OX_INV_IMAGE_PATH) then
            lib.print.error("Failed to delete existing images, aborting copy process")
            return
        end
    end
    
    lib.print.info("Starting PNG file copy process")
    lib.print.info("Source path: ^7" .. BASE_IMAGE_PATH)
    lib.print.info("Destination path: ^7" .. OX_INV_IMAGE_PATH)
    
    -- Get all PNG files recursively
    local handle = io.popen('dir "' .. BASE_IMAGE_PATH .. '" /b /s /a-d')
    if not handle then
        lib.print.error("Failed to read source directory")
        return
    end
    
    local filesCopied = 0
    local filesSkipped = 0
    
    for file in handle:lines() do
        if file:match("%.png$") then
            -- Extract just the filename from the full path
            local fileName = file:match("([^/\\]+)%.png$")
            if fileName then
                local destPath = OX_INV_IMAGE_PATH .. fileName .. ".png"
                lib.print.info("Copying: ^7" .. fileName .. ".png")
                
                -- Check if file already exists in destination (only if not force deleting)
                if not Config.ForceDeleteImagesBeforeReplicating then
                    local exists = io.open(destPath, "r")
                    if exists then
                        exists:close()
                        lib.print.warn("File already exists, skipping: ^7" .. fileName .. ".png")
                        filesSkipped = filesSkipped + 1
                        goto continue
                    end
                end
                
                if copyFile(file, destPath) then
                    lib.print.info("Copied: ^7" .. fileName .. ".png")
                    filesCopied = filesCopied + 1
                else
                    lib.print.error("Failed to copy: ^7" .. fileName .. ".png")
                end
                
                ::continue::
            end
        end
    end
    
    handle:close()
    lib.print.info(string.format("Copy process complete. Copied: %d, Skipped: %d", filesCopied, filesSkipped))
end

-- Run the copy process when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if Config.GenerateOnScriptStart then
            copyAllPngFiles()
        end
    end
end)
