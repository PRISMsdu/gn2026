// Support 3D commun aux badges UBI (Conseiller / Chambrier / Garde).
// Forme : medaillon rond simple (la fixation se gere autrement :
//         epingle, broche, aimant, agrafe arriere).
// Le DTF imprime est colle sur la face avant (z = epaisseur).
// Toutes dimensions en millimetres.

// ---- Parametres ---------------------------------------------------------

with_bail     = false; // true = ajouter une beliere d'accroche en haut
diam_med      = 60;    // diametre du medaillon
attache_l     = 6;     // (beliere) largeur du pont d'attache
attache_h     = 1;     // (beliere) hauteur visible de l'attache
diam_bel_ext  = 9;     // (beliere) diametre exterieur
diam_bel_int  = 4.5;   // (beliere) diametre du trou (cordon jusqu'a 3 mm)
epaisseur     = 3;     // epaisseur totale du support
emboit        = 1;     // (beliere) recouvrement attache/medaillon/beliere

$fn = 128;             // resolution des cercles

// ---- Geometrie ----------------------------------------------------------

module support_badge_UBI() {
    r_med  = diam_med / 2;
    r_bel  = diam_bel_ext / 2;
    y_bel  = r_med + attache_h + r_bel;

    union() {
        // Medaillon
        cylinder(h = epaisseur, d = diam_med);

        if (with_bail) {
            // Pont d'attache (chevauche legerement medaillon et beliere)
            translate([-attache_l / 2, r_med - emboit, 0])
                cube([attache_l, attache_h + 2 * emboit, epaisseur]);

            // Beliere : anneau plat
            translate([0, y_bel, 0])
                difference() {
                    cylinder(h = epaisseur, d = diam_bel_ext);
                    translate([0, 0, -0.1])
                        cylinder(h = epaisseur + 0.2, d = diam_bel_int);
                }
        }
    }
}

support_badge_UBI();

// ---- Export ------------------------------------------------------------
// Ouvrir ce fichier dans OpenSCAD, puis :
//   F5 (preview) puis F6 (render) puis "Export as STL".
// Sans beliere : medaillon rond Ø60 mm, epaisseur 3 mm.
// Avec beliere (with_bail = true) : hauteur totale 70 mm.
