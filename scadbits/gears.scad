/**
 * Return gear root radius.
 */
function sbGearRootRadius(circularPitch, numberOfTeeth) = circularPitch * numberOfTeeth / PI / 2;
/**
 * Return gear major radius.
 */
function sbGearOutsideRadius(circularPitch, numberOfTeeth, clearance=0) =
        sbGearRootRadius(circularPitch, numberOfTeeth) + circularPitch / PI - clearance;

/**
 * Really fast involute gear with cheap axle hole.
 */
module sbGear(circularPitch=3, numberOfTeeth=12, holeRadius=undef, deleteTeeth=0, pressureAngle=28, clearance=0, backlash=0) {
    function _sbInvolute(r1, r2) = sqrt((r2 / r1) * (r2 / r1) - 1) / PI * 180 - acos(r1 / r2);
    function _sbPolar(r, theta) = r * [sin(theta), cos(theta)];
    function _sbToothDerivative(delta, radius, baseRadius, majorRadius, toothThickness, edgeSign) =
            let(theta = (1 - delta) * max(baseRadius, radius) + delta * majorRadius)
            _sbPolar(theta, edgeSign * (_sbInvolute(baseRadius, theta) + toothThickness));
    
    minorRadius = sbGearRootRadius(circularPitch, numberOfTeeth);
    majorRadius = sbGearOutsideRadius(circularPitch, numberOfTeeth);
    baseRadius = minorRadius * cos(pressureAngle);
    radius = minorRadius - (majorRadius - minorRadius) - clearance;
    toothThickness = (circularPitch - backlash) / 2;
    involuteAngle = -_sbInvolute(baseRadius, minorRadius) - toothThickness / 2 / minorRadius / PI * 180;
    toothResolution = $fn ? $fn : 4;
    holeResolution = floor(toothResolution / 8);
    
    leftHoleEdge = holeRadius == undef ? [[0, 0]] : [for (i = [0 : holeResolution])
        _sbPolar(holeRadius, (181 / (i + 1)) / numberOfTeeth)
    ];
    rightHoleEdge = holeRadius == undef ? [] : [for (i = [0 : holeResolution])
        _sbPolar(holeRadius, (-181 / ((holeResolution - i) + 1)) / numberOfTeeth)
    ];
    leadingEdge = [
        _sbPolar(radius, -181 / numberOfTeeth),
        _sbPolar(radius, radius < baseRadius ? involuteAngle : -181 / numberOfTeeth)
    ];
    leftSide = [for (i = [0 : toothResolution])
         _sbToothDerivative(i / toothResolution, radius, baseRadius, majorRadius, involuteAngle, 1)
    ];
    rightSide = [for (i = [0 : toothResolution])
         _sbToothDerivative((toothResolution - i) / toothResolution, radius, baseRadius, majorRadius, involuteAngle, -1)
    ];
    tooth = concat(leftHoleEdge, rightHoleEdge, leadingEdge, leftSide, rightSide, [
        _sbPolar(radius, radius < baseRadius ? -involuteAngle : 181 / numberOfTeeth),
        _sbPolar(radius, 181 / numberOfTeeth),
    ]);
    for (i = [0 : numberOfTeeth - deleteTeeth - 1]) {
        rotate([0, 0, i * 360 / numberOfTeeth]) {
            polygon(tooth);
        }
    }
}

/**
 * Fast rack.
 */
module sbRack(linearPitch=3, numberOfTeeth=12, width=2, pressureAngle=28, backlash=0) {
    addendum = linearPitch / PI;
    toothThickness = addendum * tan(pressureAngle);
    tooth = [
        [-linearPitch * 3 / 4, -addendum - width],
        [-linearPitch * 3 / 4 - backlash, -addendum],
        [-linearPitch * 1 / 4 + backlash - toothThickness, -addendum],
        [-linearPitch * 1 / 4 + backlash + toothThickness, addendum],
        [linearPitch * 1 / 4 - backlash - toothThickness, addendum],
        [linearPitch * 1 / 4 - backlash + toothThickness, -addendum],
        [linearPitch * 3 / 4 + backlash, -addendum],
        [linearPitch * 3 / 4, -addendum - width],
    ];
    for (i = [0 : numberOfTeeth - 1] ) {
        translate([i * linearPitch, 0, 0]) {
            polygon(tooth);
        }
    }
}

/**
 * Create the animated gear designer.
 * This is best viewed 60 steps @ 60fps.
 */
module sbGearDesigner(pitch=3, holeRadius=undef, redToothCount=8, greenToothCount=16, rackToothCount=12, rackWidth=2) {
    
    r1 = sbGearRootRadius(pitch, redToothCount);
    r2 = sbGearRootRadius(pitch, redToothCount) + sbGearRootRadius(pitch, greenToothCount);

    rotate([0,0, $t * 360 / redToothCount]) {
        color("Pink") sbGear(pitch, redToothCount, holeRadius);
    }
    translate([0, r2, 0]) {
        rotate([0,0,-($t + ((greenToothCount + 1) / 2)) * 360 / greenToothCount]) {
            color("Teal") sbGear(pitch, greenToothCount, holeRadius);
        }
    }
    translate([(-floor(rackToothCount / 2) - floor(redToothCount / 2) + $t + ((redToothCount - 1) / 2)) * pitch, -r1, 0]) {
        color("SlateGray") sbRack(pitch, rackToothCount, rackWidth);
    }
}

sbGearDesigner();