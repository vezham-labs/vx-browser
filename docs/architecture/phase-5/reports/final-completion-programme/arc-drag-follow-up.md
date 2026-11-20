# Favorite reorder and equal-size Arc captures

The installed Vezham Browser UI Preview was rebuilt, audited, updated and relaunched from `/Users/vigneshwaranbhoj/Applications/Vezham Browser UI Preview.app`. The previous bundle was retained. The [installation receipt](evidence/arc-drag-03/installation.json) records the replacement executable hash.

Favorite-to-Favorite drops now place the source in the target tile's slot. The old vertical cutoff could leave the order unchanged when dropping onto a neighboring tile. The drop target now shows an outline. The new regression covers moves in both directions, rejection of self and ordinary bookmark targets, and preservation of saved item identity and URLs. All [101 Core tests](evidence/arc-drag-03/core.stdout.txt) passed. The [preview build](evidence/arc-drag-03/build.command.json) and [bundle audit](evidence/arc-drag-03/audit.command.json) passed.

Physical drag remains unverified. The installed preview held two Favorites with distinct addresses. Pointer drags tried logical and capture-pixel coordinates. The accessible order stayed unchanged, and one attempt selected address-field text. The tool run therefore did not demonstrate an accepted drop.

Native window Zoom produced equal-size **2880 × 1644** screenshots for Arc 1.172.1 build 90370 and the updated Vezham preview. Both showed the same Example Domain URL in private browsing, in dark appearance, with expanded sidebars. The original captures were emitted in the chat. Arc's page starts about 806 px from the left edge and Vezham's about 492 px. Arc shows a host-only address, a darker sidebar and an Incognito label. Vezham shows the full URL, a Space picker and explicit private-session controls. These are visually observed differences. Sidebar widths and product state differ, and the capture tool did not export local files for a pixel overlay or image diff.

The work remains uncommitted on `cross-browser-research`.
