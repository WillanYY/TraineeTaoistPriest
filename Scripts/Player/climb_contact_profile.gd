extends Resource
# Pixel-space contact points in the original, unflipped 85x128 frames.
# Frames 0-7 use the grabbing/supporting hand; 8-11 use the planted sole.
@export var contact_pixels: PackedVector2Array
@export var forward_fractions: PackedFloat32Array
@export var hand_frame_count: int = 8
