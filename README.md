# Advanced Lane Finding
By Tyler Lewis

---

The goals / steps of this project are the following:

* Compute the camera calibration matrix and distortion coefficients given a set of chessboard images.
* Apply a distortion correction to raw images.
* Use color transforms, gradients, etc., to create a thresholded binary image.
* Apply a perspective transform to rectify binary image ("birds-eye view").
* Detect lane pixels and fit to find the lane boundary.
* Determine the curvature of the lane and vehicle position with respect to center.
* Warp the detected lane boundaries back onto the original image.
* Output visual display of the lane boundaries and numerical estimation of lane curvature and vehicle position.

[//]: # (Image References)

[chessboards]: ./pipeline_test_image_output/chessboards.jpg "Distorted and Undistorted Chessboards"
[undistorted]: ./pipeline_test_image_output/1_undistorted.jpg "Original and Undistorted"
[color_and_gradient]: ./pipeline_test_image_output/3_color_binary.jpg "Color Binary and Combined Binary"
[warped]: ./pipeline_test_image_output/2_warped.jpg "Trapezoid and Warped"
[histogram]: ./pipeline_test_image_output/5_histogram.jpg "Histogram"
[window_search]: ./pipeline_test_image_output/6_window_search.jpg "Window Search"
[proximity_search]: ./pipeline_test_image_output/7_proximity_search.jpg "Proximity Search"
[final]: ./pipeline_test_image_output/11_final.jpg "Final Image"

[video1]: ./project_video.mp4 "Video"

## [Rubric](https://review.udacity.com/#!/rubrics/571/view) Points

### Here I will consider the rubric points individually and describe how I addressed each point in my implementation.

---



### Writeup / README

### Camera Calibration

#### 1. Briefly state how you computed the camera matrix and distortion coefficients. Provide an example of a distortion corrected calibration image.

The code for this step is contained under the bold "Camera Calibration" heading in the Jupyter Notebook `P4_advanced_lane_finding.ipynb`

Before we can start looking for lane lines, we need to undistort the images and videos.  Image distortion is caused by the camera lense and can be corrected using some calibration images and some functions from the OpenCV library: `cv2.findChessboardCorners` and `cv2.calibrateCamera`

Several pictures of a chessboard, located in the folder `camera_cal`, were provided for this project to be used as calibration images.  The calibration images were taken using the same camera that the project test images and videos were taken with.

Object points serve as real world coordinates of the corners of the chessboard.  Image points are detected using `cv2.findChessboardCorners` and indicate the position of the corners as they appear in the distorted images.  These points are sent to the `cv2.calibrateCamera` function which returns matrix (`mtx`) and distortion (`dist`) coefficients.  These coefficients can then be used along with the function `cv2.undistort` to undistort images and videos later on in the project.

An example of a distorted chessboard image is shown alongside its un-distorted counterpart below:

![alt text][chessboards]


### Pipeline (single images)

#### 1. Provide an example of a distortion-corrected image.

The undistorted original image is shown below:

![alt text][undistorted]

NOTE: The distortion in the original image is most noticeable near the edges of the image.


#### 2. Describe how (and identify where in your code) you used color transforms, gradients or other methods to create a thresholded binary image.  Provide an example of a binary image result.

I used a combination of color and gradient thresholds to generate the binary image called `combined_binary` (8th cell of `P4_advanced_lane_finding.ipynb`).  Here are some example images of my output for this step:

![alt text][color_and_gradient]


#### 3. Describe how (and identify where in your code) you performed a perspective transform and provide an example of a transformed image.

The `warp` function (7th cell of `P4_advanced_lane_finding.ipynb`) returns a "birds-eye-view" version of the input image.  The function re-maps a set of source (`src`) points to the destination (`dst`) points.  The source points correspond to the trapezoid verteces.  The source points are hard-coded in but are designed to be easily manipulated based on image dimensions and desired trapezoid position and size.

```python
# Define trapezoid dimensions
trap_height = 260
trap_top_width = 170
trap_base_width = img_w-100
trap_bottom_cutoff = 40
trap_v_shift = 0   # positive --> shifts entire trapezoid UP
trap_h_shift = 0   # positive --> shifts entire trapezoid to the RIGHT

# Store 4 trapezoid vertices in 'src' (...starting with top left point going clockwise)
src = np.float32(
    [[x_mid + trap_h_shift - trap_top_width//2, img_h - trap_v_shift - trap_height],
     [x_mid + trap_h_shift + trap_top_width//2, img_h - trap_v_shift - trap_height],
     [x_mid + trap_h_shift + trap_base_width//2, img_h - trap_v_shift - trap_bottom_cutoff],
     [x_mid + trap_h_shift - trap_base_width//2, img_h - trap_v_shift - trap_bottom_cutoff]])

# The 4 points from 'src' will be mapped to these 4 points
# NOTE: 'offset' is the padding added to the left and right sides of the warped image
top_offset = 200
base_offset = top_offset - 60
img_size = (img_w, img_h)

# The 4 trapezoid vertices will be remapped to these 'dst' points
dst = np.float32([[top_offset, 0],
                  [img_w-top_offset, 0],
                  [img_w-base_offset, img_h],
                  [base_offset, img_h]])
```

The result of the `warp` function is shown below:

![alt text][warped]

#### 4. Describe how (and identify where in your code) you identified lane-line pixels and fit their positions with a polynomial.

There were two search functions used to determine which of the pixels in `combined_binary` belonged to lane lines: window_search and `proximity_search`.  `window_search` was only used for the very first frame in the video.  All other frames used `proximity_search` to find the lane line points.

To perform a window search, a histogram must first be created using the `make_histogram` function (9th cell of `P4_advanced_lane_finding.ipynb`).  An example histogram is shown below:

![alt text][histogram]

The `window_search` function (10th cell of `P4_advanced_lane_finding.ipynb`) was used to create the image above.  The windows stack vertically from the bottom, starting at the left and right histogram peak x-coordinates, and re-centering themselves on the lane each time.  Once all of the windows have been created, the points that are contained within the windows are used to fit a 2nd-order polynomial curve.  (Two independent curves are created; one for the left set of points and one for the right set of points.)

![alt text][window_search]

The `proximity_search` function (11th cell of `P4_advanced_lane_finding.ipynb`) is used for every frame other than the first frame.  The previous frame's two fitted polynomial curves are used to create "proximity zones".  The points from the current frame's image that lay within the proximity zones are collected and two new polynomial curves are fit to these points. The proximity zones are the two thick green areas shown below:

![alt text][proximity_search]


#### 5. Describe how (and identify where in your code) you calculated the radius of curvature of the lane and the position of the vehicle with respect to center.

The radius of curvature (`avg_curverad`) and vehicle's distance from center (`distance_from_center`) were calculated inside the `window_search` and `proximity_search` functions.  The radius of curvature was averaged over several frames to produce a more accurate and less 'jumpy' result.  The distance from center was calculated by looking at the left and right line polynomial curves' x-intercept positions on the bottom edge of the image.  A `dfc_correction_factor` was added and can be used to calibrate the position of the vehicle relative to the camera if the camera is not mounted perfectly in the center of the vehicle.


#### 6. Provide an example image of your result plotted back down onto the road such that the lane area is identified clearly.

The area between the two polynomial curves is filled in with the color green using the `cv2.fillPoly` function (12th cell of `P4_advanced_lane_finding.ipynb`).  The filled polygon is warped back to the original position and the radius of curvature and the vehicle distance from center information are added to produce the final image of the pipeline:

![alt text][final]

---

### Pipeline (video)

#### 1. Provide a link to your final video output.  Your pipeline should perform reasonably well on the entire project video (wobbly lines are ok but no catastrophic failures that would cause the car to drive off the road!).

Here's a [link to my video result](./project_video_output.mp4)

---

### Discussion

#### 1. Briefly discuss any problems / issues you faced in your implementation of this project.  Where will your pipeline likely fail?  What could you do to make it more robust?

Some problems I faced while working on this project were mainly due to the color and gradient thresholding step.  The portions of the road that are heavily shaded or very lightly colored would cause the `color_and_gradient_mask` function (8th cell in `P4_advanced_lane_finding.ipynb`) to fail.  The function would collect noise from the shadowy areas which would cause the search functions to produce poor polynomial curve fits.

I tried to implement some basic lane detection failure criteria to help filter out poor search results.  If the search function returned a polynomial that was too "curvy" to be a lane line, the curve was discarded and the curve from the previous frame was used.  Also, if any portion of the left lane curve crossed over into the right half of the image, or any portion of the right lane curve crossed over into the left half of the image, the curves would be discarded and replaced with the previous frame's curves.  The curves were also averaged over three frames to reduce drastic jumps in position from frame to frame due to noise.

To improve the pipeline, I might consider measuring the change in curve location from frame to frame.  If the location of the curve is drastically different from the previous frame's curve location, then the current frame's curve is probably incorrect and should be discarded.

Another improvement that could be made is to add more color thresholds from different color spaces.  (I could use several "strict" color filters instead of just a couple "lenient" color filters).  An "auto-thresholding" or image normalization step might also help.

Finally, a "robustness" attribute could be added to each polynomial curve fit.  Similarity to the previous frame's line shape and having a high number of points detected in the search function would yield a higher "robustness" score.  The robustness could then be used to weigh each line appropriately and produce a wieghted average polynomial curve.
