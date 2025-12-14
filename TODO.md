## TODOS

- [ ] BUG: When Capture folder changes in Capture One, the new capture folder name is displayed, but no images appear (in the filmstrip or mainview)
- [ ] Add setting: Show/hide image name extension (e.g. .CR3)
- [ ] Move the image name to an overlay, instead of below image and increase vertical spacing
    - [ ] Settings: Add option to show/hide images names in filmstrip
- [ ] Remove dead space at top of menu bar
- [ ] Fix thumbnails not showing while higher res image loads
- [ ] Settings: The thumbnail size dropdown isn't working
- [ ] Multi-image view bug: Before new image loads, selection highlight surrounds whole div
- [ ] Bug: Session not detected via Bonjour (it's launched on the local machine, which could be causing issues. Network permission has been granted in system prefs)
- [ ] Bug: Placeholder rectangles in filmstrip are not necessarily the same aspect ratio as the images once they load in
- [ ] Remove lighter inner box bg from manual address fields
- [ ] HUD: Change tag colour circle to square with 4px corner radius. Make smaller

## COMPLETED

- [x] Add settings. Show/hide: color tag, star rating, exif
    - [x] If all unticked, HUD not shown
- [x] The connect button on the first screen should sit on the same line as the address fields
- [x] Allow rating of images with keyboard 0-5
- [x] Fix the Selects button appearance: the text "Selects" is currently split over two lines
    - [x] Make the "S" the same size as the S in Selects
- [x] Clicking an image in main view when multiple images are selected should focus that image (not switch back to single image view)
- [x] Move the capture folder name (currently in the HUD) to the top bar. Replacing "Capture Folder"
- [x] Add left/right padding to the images in the sidebar
    - [x] Increase the padding further
- [x] Styling: Change the HUD material to bar. Reduce corner rounding slightly
