// ==========================================
// Tests unitaires : Matrix3, Matrix4 et Quaternion
// ------------------------------------------
// Utilisation (par exemple dans setup()) :
//   new MathTests().run();
// Chaque suite affiche "<Classe>: All tests passed!" ou la liste des tests échoués.
// ==========================================

class MathTests {

    int m_failures = 0;

    void run() {
        m_failures = 0;
        testMatrix3();
        testMatrix4();
        testQuaternion();
        testQuaternionSlerp(); // BONUS (non demandé) : à retirer avec Quaternion.slerp()
        if (m_failures == 0) {
            println("MathTests: All tests passed!");
        } else {
            println("MathTests: " + m_failures + " test(s) FAILED");
        }
    }

    // ------------------------------------------------------------------
    // Matrix3
    // ------------------------------------------------------------------
    void testMatrix3() {
        boolean passed = true;

        // --- Construction et accès ---
        Matrix3 id = new Matrix3();
        passed &= expect(id.equals(new Matrix3(1, 0, 0, 0, 1, 0, 0, 0, 1)), "Matrix3 default is identity");

        Matrix3 a = new Matrix3(1, 2, 3,
                                0, 1, 4,
                                5, 6, 0);
        passed &= expect(a.get(0, 1) == 2.0f && a.get(1, 2) == 4.0f && a.get(2, 0) == 5.0f, "Matrix3 constructor and get");

        Matrix3 copy = new Matrix3(a);
        copy.set(0, 0, 42.0f);
        passed &= expect(copy.get(0, 0) == 42.0f && a.get(0, 0) == 1.0f, "Matrix3 copy constructor is independent, set works");

        passed &= expect(a.getRow(1).equals(new Vector3D(0, 1, 4)), "Matrix3 getRow");
        passed &= expect(a.getColumn(2).equals(new Vector3D(3, 4, 0)), "Matrix3 getColumn");

        try {
            a.get(3, 0);
            passed &= expect(false, "Matrix3 get out of range should throw");
        } catch (IndexOutOfBoundsException e) {
            passed &= expect(true, "Matrix3 get out of range throws");
        }

        // --- Opérations élémentaires ---
        Matrix3 b = new Matrix3(1, 1, 1,
                                1, 1, 1,
                                1, 1, 1);
        passed &= expect(a.add(b).equals(new Matrix3(2, 3, 4, 1, 2, 5, 6, 7, 1)), "Matrix3 add");
        passed &= expect(a.sub(b).equals(new Matrix3(0, 1, 2, -1, 0, 3, 4, 5, -1)), "Matrix3 sub");
        passed &= expect(a.mult(2.0f).equals(new Matrix3(2, 4, 6, 0, 2, 8, 10, 12, 0)), "Matrix3 mult(scalar)");

        // --- Produit matriciel ---
        Matrix3 c = new Matrix3(1, 0, 2,
                                0, 1, 0,
                                3, 0, 1);
        // a * c calculé à la main
        passed &= expect(a.mult(c).equals(new Matrix3(10, 2, 5, 12, 1, 4, 5, 6, 10)), "Matrix3 mult(matrix)");
        passed &= expect(!a.mult(c).equals(c.mult(a)), "Matrix3 mult is not commutative");
        passed &= expect(a.mult(id).equals(a) && id.mult(a).equals(a), "Matrix3 identity is neutral");

        // --- Matrice x vecteur ---
        Vector3D v = new Vector3D(1, 2, 3);
        passed &= expect(a.transform(v).equals(new Vector3D(14, 14, 17)), "Matrix3 transform(vector)");
        passed &= expect(a.transformTranspose(v).equals(a.transpose().transform(v)), "Matrix3 transformTranspose == transpose().transform");

        // --- Transposée, déterminant, inverse ---
        passed &= expect(a.transpose().equals(new Matrix3(1, 0, 5, 2, 1, 6, 3, 4, 0)), "Matrix3 transpose");
        passed &= expect(a.transpose().transpose().equals(a), "Matrix3 transpose twice is identity operation");
        passed &= expect(approx(a.determinant(), 1.0f), "Matrix3 determinant");
        passed &= expect(approx(id.determinant(), 1.0f), "Matrix3 determinant of identity");
        passed &= expect(approx(a.mult(c).determinant(), a.determinant() * c.determinant()), "Matrix3 det(AB) = det(A) det(B)");

        passed &= expect(a.inverse().equals(new Matrix3(-24, 18, 5, 20, -15, -4, -5, 4, 1)), "Matrix3 inverse (known values)");
        passed &= expect(a.mult(a.inverse()).equals(id) && a.inverse().mult(a).equals(id), "Matrix3 M * M^-1 = I");

        try {
            b.inverse();
            passed &= expect(false, "Matrix3 inverse of singular matrix should throw");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Matrix3 inverse of singular matrix throws");
        }

        // --- Tenseurs d'inertie ---
        Matrix3 diag = new Matrix3();
        diag.setDiagonal(1, 2, 3);
        passed &= expect(diag.equals(new Matrix3(1, 0, 0, 0, 2, 0, 0, 0, 3)), "Matrix3 setDiagonal");

        Matrix3 coeffs = new Matrix3();
        coeffs.setInertiaTensorCoeffs(1, 2, 3, 4, 5, 6);
        passed &= expect(coeffs.equals(new Matrix3(1, -4, -5, -4, 2, -6, -5, -6, 3)), "Matrix3 setInertiaTensorCoeffs");
        passed &= expect(coeffs.equals(coeffs.transpose()), "Matrix3 inertia tensor is symmetric");

        Matrix3 box = new Matrix3();
        box.setCuboidInertiaTensor(12.0f, 1.0f, 2.0f, 3.0f); // m/12 = 1
        passed &= expect(box.equals(new Matrix3(13, 0, 0, 0, 10, 0, 0, 0, 5)), "Matrix3 setCuboidInertiaTensor");

        Matrix3 cube = new Matrix3();
        cube.setCuboidInertiaTensor(6.0f, 2.0f, 2.0f, 2.0f); // cube : m * a² / 6 = 4 sur chaque axe
        passed &= expect(cube.equals(new Matrix3(4, 0, 0, 0, 4, 0, 0, 0, 4)), "Matrix3 cube inertia tensor");

        // --- Rotation ---
        Matrix3 rotZ = new Matrix3(new Quaternion(new Vector3D(0, 0, 1), HALF_PI));
        passed &= expect(rotZ.transform(new Vector3D(1, 0, 0)).equals(new Vector3D(0, 1, 0)), "Matrix3 rotation 90deg around Z: X -> Y");
        passed &= expect(rotZ.getColumn(0).equals(new Vector3D(0, 1, 0)), "Matrix3 rotation columns are rotated axes");
        passed &= expect(rotZ.mult(rotZ.transpose()).equals(id), "Matrix3 rotation is orthogonal (R R^T = I)");
        passed &= expect(rotZ.transpose().equals(rotZ.inverse()), "Matrix3 rotation inverse = transpose");
        passed &= expect(approx(rotZ.determinant(), 1.0f), "Matrix3 rotation determinant = 1");

        Matrix3 rotAny = new Matrix3(new Quaternion(new Vector3D(1, 2, 3), 0.7f));
        passed &= expect(rotAny.mult(rotAny.transpose()).equals(id), "Matrix3 arbitrary rotation is orthogonal");

        // Comparaison avec la rotation de Processing (PMatrix3D.rotate)
        PMatrix3D pm = new PMatrix3D();
        Vector3D axis = new Vector3D(1, 2, 3).normalized();
        pm.rotate(0.7f, axis.getX(), axis.getY(), axis.getZ());
        Matrix3 fromProcessing = new Matrix3(pm.m00, pm.m01, pm.m02,
                                             pm.m10, pm.m11, pm.m12,
                                             pm.m20, pm.m21, pm.m22);
        passed &= expect(rotAny.equals(fromProcessing), "Matrix3 rotation matches Processing PMatrix3D.rotate");

        // --- Changement de base du tenseur d'inertie ---
        // Rotation de 90deg autour de Z : l'axe X local devient Y monde, donc Ixx et Iyy s'échangent.
        passed &= expect(diag.changeBasis(rotZ).equals(new Matrix3(2, 0, 0, 0, 1, 0, 0, 0, 3)), "Matrix3 changeBasis swaps inertia axes");
        passed &= expect(diag.changeBasis(rotZ).inverse().equals(diag.inverse().changeBasis(rotZ)), "Matrix3 changeBasis commutes with inverse");

        // --- toString ---
        passed &= expect(new Matrix3().toString().equals("Matrix3([1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0])"), "Matrix3 toString format");

        report(passed, "Matrix3");
    }

    // ------------------------------------------------------------------
    // Matrix4
    // ------------------------------------------------------------------
    void testMatrix4() {
        boolean passed = true;

        // --- Construction et accès ---
        Matrix4 id = new Matrix4();
        passed &= expect(id.equals(new Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)), "Matrix4 default is identity");

        Matrix4 a = new Matrix4(2, 0, 0, 1,
                                1, 3, 0, 0,
                                0, 1, 4, 0,
                                0, 0, 1, 5);
        passed &= expect(a.get(0, 3) == 1.0f && a.get(3, 2) == 1.0f && a.get(2, 2) == 4.0f, "Matrix4 constructor and get");

        Matrix4 copy = new Matrix4(a);
        copy.set(1, 1, 42.0f);
        passed &= expect(copy.get(1, 1) == 42.0f && a.get(1, 1) == 3.0f, "Matrix4 copy constructor is independent, set works");

        try {
            a.set(0, 4, 1.0f);
            passed &= expect(false, "Matrix4 set out of range should throw");
        } catch (IndexOutOfBoundsException e) {
            passed &= expect(true, "Matrix4 set out of range throws");
        }

        // --- Produit, transposée, déterminant, inverse ---
        passed &= expect(a.mult(id).equals(a) && id.mult(a).equals(a), "Matrix4 identity is neutral");
        passed &= expect(a.mult(2.0f).get(2, 2) == 8.0f, "Matrix4 mult(scalar)");
        passed &= expect(a.transpose().get(3, 0) == 1.0f && a.transpose().get(0, 3) == 0.0f, "Matrix4 transpose");
        passed &= expect(a.transpose().transpose().equals(a), "Matrix4 transpose twice is identity operation");

        Matrix4 diag = new Matrix4(2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0, 0, 0, 0, 5);
        passed &= expect(approx(diag.determinant(), 120.0f), "Matrix4 determinant of diagonal");
        passed &= expect(approx(id.determinant(), 1.0f), "Matrix4 determinant of identity");
        passed &= expect(approx(a.determinant(), 119.0f), "Matrix4 determinant (known value)");
        passed &= expect(approx(a.mult(diag).determinant(), a.determinant() * diag.determinant(), 10.0f), "Matrix4 det(AB) = det(A) det(B)");

        passed &= expect(a.mult(a.inverse()).equals(id) && a.inverse().mult(a).equals(id), "Matrix4 M * M^-1 = I (general matrix)");
        passed &= expect(diag.inverse().equals(new Matrix4(0.5f, 0, 0, 0, 0, 1.0f / 3.0f, 0, 0, 0, 0, 0.25f, 0, 0, 0, 0, 0.2f)), "Matrix4 inverse of diagonal");

        try {
            new Matrix4(1, 2, 3, 4, 2, 4, 6, 8, 0, 0, 1, 0, 0, 0, 0, 1).inverse();
            passed &= expect(false, "Matrix4 inverse of singular matrix should throw");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Matrix4 inverse of singular matrix throws");
        }

        // --- Transformation d'un corps rigide ---
        Quaternion rot90z = new Quaternion(new Vector3D(0, 0, 1), HALF_PI);
        Point3D position = new Point3D(10, 0, 0);
        Matrix4 t = new Matrix4(rot90z, position);

        passed &= expect(t.transform(new Point3D(1, 0, 0)).equals(new Point3D(10, 1, 0)), "Matrix4 transform(point) rotates then translates");
        passed &= expect(t.transformDirection(new Vector3D(1, 0, 0)).equals(new Vector3D(0, 1, 0)), "Matrix4 transformDirection ignores translation");
        passed &= expect(t.getPosition().equals(position), "Matrix4 getPosition");
        passed &= expect(t.getAxis(0).equals(new Vector3D(0, 1, 0)) && t.getAxis(2).equals(new Vector3D(0, 0, 1)), "Matrix4 getAxis (local axes in world)");
        passed &= expect(t.getAxis(3).equals(new Vector3D(10, 0, 0)), "Matrix4 getAxis(3) is translation");
        passed &= expect(t.getRotation().equals(new Matrix3(rot90z)), "Matrix4 getRotation");
        passed &= expect(approx(t.determinant(), 1.0f), "Matrix4 rigid transform determinant = 1");

        Point3D worldPoint = new Point3D(3, -2, 7);
        passed &= expect(t.transform(t.transformInverse(worldPoint)).equals(worldPoint), "Matrix4 transformInverse round trip");
        passed &= expect(t.transformInverse(worldPoint).equals(t.inverse().transform(worldPoint)), "Matrix4 transformInverse == inverse().transform");
        Vector3D worldDir = new Vector3D(0.5f, 1, -2);
        passed &= expect(t.transformDirection(t.transformInverseDirection(worldDir)).equals(worldDir), "Matrix4 transformInverseDirection round trip");

        // Composition : translation puis rotation
        Matrix4 translation = new Matrix4(new Quaternion(), new Point3D(0, 5, 0));
        Matrix4 rotation = rot90z.toMatrix4();
        Point3D p = new Point3D(1, 0, 0);
        passed &= expect(translation.mult(rotation).transform(p).equals(translation.transform(rotation.transform(p))), "Matrix4 mult composes transforms (right applied first)");
        passed &= expect(translation.mult(rotation).transform(p).equals(new Point3D(0, 6, 0)), "Matrix4 composition known value");

        // Coordonnées homogènes : w != 1
        Matrix4 homogeneous = new Matrix4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 2);
        passed &= expect(homogeneous.transform(new Point3D(2, 4, 6)).equals(new Point3D(1, 2, 3)), "Matrix4 transform divides by w");

        // Comparaison avec Processing (translate + rotate)
        Quaternion q = new Quaternion(new Vector3D(1, 2, 3), 0.7f);
        Vector3D axis = q.getRotationAxis();
        PMatrix3D pm = new PMatrix3D();
        pm.translate(4, 5, 6);
        pm.rotate(0.7f, axis.getX(), axis.getY(), axis.getZ());
        PMatrix3D mine = new Matrix4(q, new Point3D(4, 5, 6)).toPMatrix3D();
        float[] expected = pm.get(null);
        float[] actual = mine.get(null);
        boolean same = true;
        for (int i = 0; i < 16; i++) same &= approx(expected[i], actual[i]);
        passed &= expect(same, "Matrix4 toPMatrix3D matches Processing translate + rotate");

        // --- toString ---
        passed &= expect(id.toString().equals("Matrix4([1.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0])"), "Matrix4 toString format");

        report(passed, "Matrix4");
    }

    // ------------------------------------------------------------------
    // Quaternion
    // ------------------------------------------------------------------
    void testQuaternion() {
        boolean passed = true;
        Quaternion identity = new Quaternion();

        // --- Construction et accès ---
        passed &= expect(identity.getW() == 1 && identity.getX() == 0 && identity.getY() == 0 && identity.getZ() == 0, "Quaternion default is identity");

        Quaternion q = new Quaternion(1, 2, 3, 4);
        passed &= expect(q.getW() == 1 && q.getX() == 2 && q.getY() == 3 && q.getZ() == 4, "Quaternion constructor and getters");

        Quaternion s = new Quaternion();
        s.setW(5); s.setX(6); s.setY(7); s.setZ(8);
        passed &= expect(s.equals(new Quaternion(5, 6, 7, 8)), "Quaternion setters");
        s.set(1, 2, 3, 4);
        passed &= expect(s.equals(q), "Quaternion set(w, x, y, z)");

        Quaternion copy = new Quaternion(q);
        copy.setW(9);
        passed &= expect(q.getW() == 1, "Quaternion copy constructor is independent");

        // --- Axe-angle ---
        Quaternion halfTurnY = new Quaternion(new Vector3D(0, 5, 0), PI); // axe non normalisé volontairement
        passed &= expect(halfTurnY.equals(new Quaternion(0, 0, 1, 0)), "Quaternion from axis-angle (180deg around Y)");
        Quaternion rot90z = new Quaternion(new Vector3D(0, 0, 1), HALF_PI);
        float h = (float)Math.sqrt(0.5);
        passed &= expect(rot90z.equals(new Quaternion(h, 0, 0, h)), "Quaternion from axis-angle (90deg around Z)");
        passed &= expect(approx(rot90z.length(), 1.0f), "Quaternion from axis-angle is unit");

        try {
            new Quaternion(new Vector3D(0, 0, 0), 1.0f);
            passed &= expect(false, "Quaternion zero axis should throw");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Quaternion zero axis throws");
        }

        // --- Norme ---
        passed &= expect(q.lengthSquared() == 30.0f, "Quaternion lengthSquared");
        passed &= expect(approx(q.length(), (float)Math.sqrt(30)), "Quaternion length");

        Quaternion toNormalize = new Quaternion(0, 3, 0, 4);
        float oldLength = toNormalize.normalize();
        passed &= expect(approx(oldLength, 5.0f) && toNormalize.equals(new Quaternion(0, 0.6f, 0, 0.8f)), "Quaternion normalize (in place)");
        passed &= expect(approx(q.normalized().length(), 1.0f) && q.lengthSquared() == 30.0f, "Quaternion normalized (new instance)");

        Quaternion zero = new Quaternion(0, 0, 0, 0);
        zero.normalize();
        passed &= expect(zero.equals(identity), "Quaternion normalize of zero gives identity");

        // --- Opérations élémentaires ---
        Quaternion r = new Quaternion(5, 6, 7, 8);
        passed &= expect(q.dot(r) == 70.0f, "Quaternion dot");
        passed &= expect(q.add(r).equals(new Quaternion(6, 8, 10, 12)), "Quaternion add");
        passed &= expect(q.mult(2.0f).equals(new Quaternion(2, 4, 6, 8)), "Quaternion mult(scalar)");
        passed &= expect(q.negate().equals(new Quaternion(-1, -2, -3, -4)), "Quaternion negate");
        passed &= expect(q.conjugate().equals(new Quaternion(1, -2, -3, -4)), "Quaternion conjugate");
        passed &= expect(q.mult(q.inverse()).equals(identity) && q.inverse().mult(q).equals(identity), "Quaternion q * q^-1 = identity");
        passed &= expect(rot90z.inverse().equals(rot90z.conjugate()), "Quaternion unit inverse = conjugate");

        try {
            new Quaternion(0, 0, 0, 0).inverse();
            passed &= expect(false, "Quaternion inverse of zero should throw");
        } catch (IllegalArgumentException e) {
            passed &= expect(true, "Quaternion inverse of zero throws");
        }

        // --- Produit de Hamilton ---
        Quaternion i = new Quaternion(0, 1, 0, 0);
        Quaternion j = new Quaternion(0, 0, 1, 0);
        Quaternion k = new Quaternion(0, 0, 0, 1);
        passed &= expect(i.mult(j).equals(k), "Quaternion i * j = k");
        passed &= expect(j.mult(i).equals(k.negate()), "Quaternion j * i = -k (non commutative)");
        passed &= expect(i.mult(i).equals(new Quaternion(-1, 0, 0, 0)), "Quaternion i * i = -1");
        passed &= expect(i.mult(j).mult(k).equals(new Quaternion(-1, 0, 0, 0)), "Quaternion i * j * k = -1");
        passed &= expect(q.mult(r).equals(new Quaternion(-60, 12, 30, 24)), "Quaternion Hamilton product (known value)");
        passed &= expect(q.mult(identity).equals(q) && identity.mult(q).equals(q), "Quaternion identity is neutral");

        // --- Rotation de vecteurs ---
        Vector3D x = new Vector3D(1, 0, 0);
        passed &= expect(rot90z.rotate(x).equals(new Vector3D(0, 1, 0)), "Quaternion rotate 90deg around Z: X -> Y");
        passed &= expect(identity.rotate(new Vector3D(1, 2, 3)).equals(new Vector3D(1, 2, 3)), "Quaternion identity rotation");

        Quaternion qa = new Quaternion(new Vector3D(1, 2, 3), 0.7f);
        Quaternion qb = new Quaternion(new Vector3D(-1, 0, 2), 1.3f);
        Vector3D v = new Vector3D(2, -1, 0.5f);
        passed &= expect(approx(qa.rotate(v).length(), v.length()), "Quaternion rotation preserves length");
        passed &= expect(qa.mult(qb).rotate(v).equals(qa.rotate(qb.rotate(v))), "Quaternion composition: (qa * qb) applies qb first");
        passed &= expect(rot90z.mult(rot90z).sameRotation(new Quaternion(new Vector3D(0, 0, 1), PI)), "Quaternion 90deg + 90deg = 180deg");
        passed &= expect(qa.rotate(v).equals(qa.toMatrix3().transform(v)), "Quaternion rotate == toMatrix3().transform");
        passed &= expect(qa.mult(3.0f).rotate(v).equals(qa.rotate(v)), "Quaternion rotate works on non-unit quaternion");

        // --- Conversions ---
        passed &= expect(approx(qa.getRotationAngle(), 0.7f), "Quaternion getRotationAngle");
        passed &= expect(qa.getRotationAxis().equals(new Vector3D(1, 2, 3).normalized()), "Quaternion getRotationAxis");
        passed &= expect(approx(identity.getRotationAngle(), 0.0f) && identity.getRotationAxis().equals(x), "Quaternion identity angle 0, default axis X");
        passed &= expect(new Quaternion(qa.getRotationAxis(), qa.getRotationAngle()).equals(qa), "Quaternion axis-angle round trip");

        Matrix4 m4 = qa.toMatrix4();
        passed &= expect(m4.getRotation().equals(qa.toMatrix3()) && m4.getPosition().equals(new Point3D()), "Quaternion toMatrix4 is a pure rotation");

        // --- Intégration (addScaledVector) ---
        Quaternion step = new Quaternion();
        step.addScaledVector(new Vector3D(0, 0, 2), 0.1f); // q += 0.5 * (0, 0, 0, 0.2) * (1, 0, 0, 0)
        passed &= expect(step.equals(new Quaternion(1, 0, 0, 0.1f)), "Quaternion addScaledVector single step");

        Quaternion integrated = new Quaternion();
        Vector3D omega = new Vector3D(0, 0, HALF_PI); // 90deg par seconde autour de Z
        float dt = 0.001f;
        for (int n = 0; n < 1000; n++) {
            integrated.addScaledVector(omega, dt);
            integrated.normalize();
        }
        passed &= expect(approxQuat(integrated, rot90z, 1e-3f), "Quaternion addScaledVector integrates 1 s at 90deg/s -> 90deg rotation");
        passed &= expect(approx(integrated.length(), 1.0f), "Quaternion stays unit after integration + normalize");

        Quaternion zeroOmega = new Quaternion(qa);
        zeroOmega.addScaledVector(new Vector3D(), 0.5f);
        passed &= expect(zeroOmega.equals(qa), "Quaternion addScaledVector with zero angular velocity changes nothing");

        // --- Comparaisons ---
        passed &= expect(qa.sameRotation(qa.negate()) && !qa.equals(qa.negate()), "Quaternion q and -q: same rotation, not equal");
        passed &= expect(!qa.sameRotation(qb), "Quaternion different rotations");
        passed &= expect(q.toString().equals("Quaternion(1.0, 2.0, 3.0, 4.0)"), "Quaternion toString format");

        report(passed, "Quaternion");
    }

    // ------------------------------------------------------------------
    // BONUS — NON DEMANDÉ : tests de Quaternion.slerp().
    // À supprimer (ainsi que l'appel dans run()) si slerp est retiré.
    // ------------------------------------------------------------------
    void testQuaternionSlerp() {
        boolean passed = true;
        Quaternion a = new Quaternion();
        Quaternion b = new Quaternion(new Vector3D(0, 0, 1), HALF_PI);

        passed &= expect(a.slerp(b, 0.0f).equals(a), "Slerp t = 0 gives start");
        passed &= expect(a.slerp(b, 1.0f).equals(b), "Slerp t = 1 gives end");
        passed &= expect(a.slerp(b, 0.5f).equals(new Quaternion(new Vector3D(0, 0, 1), QUARTER_PI)), "Slerp t = 0.5 gives half angle");
        passed &= expect(approx(a.slerp(b, 0.3f).length(), 1.0f), "Slerp result is unit");
        passed &= expect(a.slerp(b.negate(), 0.5f).sameRotation(a.slerp(b, 0.5f)), "Slerp takes the shortest path (q vs -q)");

        Quaternion near = new Quaternion(new Vector3D(0, 0, 1), 0.001f);
        passed &= expect(a.slerp(near, 0.5f).equals(new Quaternion(new Vector3D(0, 0, 1), 0.0005f)), "Slerp on nearly identical quaternions");

        report(passed, "Quaternion slerp (bonus)");
    }

    // ------------------------------------------------------------------
    // Outils
    // ------------------------------------------------------------------
    boolean expect(boolean condition, String name) {
        if (!condition) {
            println("  [FAILED] " + name);
            m_failures++;
        }
        return condition;
    }

    void report(boolean passed, String suite) {
        if (passed) println(suite + ": All tests passed!");
    }

    boolean approx(float a, float b) {
        return MathHelpers.equalComponents(a, b);
    }

    boolean approx(float a, float b, float toleranceMultiplier) {
        return MathHelpers.equalComponents(a, b, toleranceMultiplier);
    }

    boolean approxQuat(Quaternion a, Quaternion b, float tolerance) {
        return Math.abs(a.getW() - b.getW()) < tolerance && Math.abs(a.getX() - b.getX()) < tolerance &&
               Math.abs(a.getY() - b.getY()) < tolerance && Math.abs(a.getZ() - b.getZ()) < tolerance;
    }
}
