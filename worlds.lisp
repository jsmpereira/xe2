;;; worlds.lisp --- turn-based cell/sprite worlds

;; Copyright (C) 2008  David O'Toole

;; Author: David O'Toole <dto@gnu.org>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

(in-package :xe2)

(define-prototype world
    (:parent =page=
	     :documentation "An XE2 game world filled with cells and sprites.
Worlds are the focus of the action in XE2. A world is a 3-D grid of
interacting cells. The world object performs the following tasks:

  - Keeps track of a single player in a world of cells
  - Receives command messages from the user
  - Handles some messages, forwards the rest on to the player cell.
  - Runs the CPU phase so that all non-player :actor cells get their turns
  - Keeps track of lit squares 
  - Performs collision detection for sprites and cells
")
  (name :initform nil :documentation "Name of the world.")
  (overworld :initform nil)
  (paused :initform nil :documentation "Non-nil when the game is paused.")
  (description :initform "Unknown area." :documentation "Brief description of area.")
  (background :initform nil
	      :documentation "String name of image to use as background.")
  (tile-size :initform 16 :documentation "Size in pixels of a grid tile.")
  (required-modes :initform nil :documentation 
"A list of keywords specifying which modes of transportation are
required for travel here." )
  (categories :initform nil :documentation "The set of categories this world is in.")
  ;; turtle graphics
  (grammar :initform '() :documentation "Context-free grammar for level generation.")
  (stack :initform '() :documentation "Stack for logo system.")
  (row :initform 0)
  (column :initform 0)
  (direction :initform :east)
  (paint :initform nil)
  ;;
  (scale :initform '(1 m)
	 :documentation "Scale per square side in the form (N UNIT) where UNIT is m, km, ly etc.")
  (player :documentation "The player cell (or sprite).")
  (width :initform 16 :documentation "The width of the world map, measured in tiles.")
  (height :initform 16 :documentation "The height of the world map, measured in tiles.")
  ;; sprite cells
  (sprites :initform nil :documentation "A list of sprites.")
  (sprite-grid :initform nil :documentation "Grid for collecting sprite collision information.")
  (sprite-table :initform nil :documentation "Hash table to prevent redundant collisions.")
  ;; environment 
  (environment-grid :documentation "A two-dimensional array of environment data cells.")
  ;; lighting 
  (automapped :initform nil :documentation "Show all previously lit squares.")
  (light-grid 
   :documentation 
   "A 2d array of integers giving the light level at that point in <grid>.
At the moment, only 0=off and 1=on are supported.")
  (ambient-light :initform :total :documentation 
		 "Radius of ambient visibility. :total means that lighting is turned off.")
  ;; action-points 
  (phase-number :initform 1 :documentation "Integer number of current phase.")
  (turn-number :initform 1 :documentation "Integer number of elapsed user turns (actions).")
  ;; narration 
  (narrator :documentation "The narration widget object.")
  ;; browsing 
  (browser :documentation "The browser object.")
  ;; viewing
  (viewport :initform nil :documentation "The viewport object.")
  ;; space
  (edge-condition :initform :exit
		  :documentation "Either :block the player, :exit the world, or :wrap around.")
  (exited :initform nil
	  :documentation "Non-nil when the player has exited. See also `forward'.")
  (player-exit-row :initform 0)
  (player-exit-column :initform 0)
  ;; serialization
  (excluded-fields :initform
  '(:stack :paint :sprite-grid :sprite-table :narrator :browser :viewport :grid
    :message-queue :player)))

(defparameter *default-world-axis-size* 10)
(defparameter *default-world-z-size* 4)

;; (define-method initialize world (&key height width)
;;   (when height (setf <height> height))
;;   (when width (setf <width> width))
;;   (setf <variables> (make-hash-table :test 'equal))
;;   (/create-default-grid self))

(define-method in-category world (category)
  "Returns non-nil when the cell SELF is in the category CATEGORY."
  (member category <categories>))
    
(define-method pause world (&optional always)
  "Toggle the pause state of the world."
  (clon:with-fields (paused) self
    (setf paused (if (null paused)
		     t (when always t)))
    (if (null paused)
	(/narrateln <narrator> "Resuming game.")
	(/narrateln <narrator> "The game is now paused. Press Control-P or PAUSE to un-pause."))))

(define-prototype environment
    (:documentation "A cell giving general environmental conditions at a world location.")
  (temperature :initform nil :documentation "Temperature at this location, in degrees Celsius.")
  (radiation-level :initform nil :documentation "Radiation level at this location, in clicks.")
  (oxygen :initform nil :documentation "Oxygen level, in percent.")
  (pressure :initform nil :documentation "Atmospheric pressure, in multiples of Earth's.")
  (overlay :initform nil 
	   :documentation "Possibly transparent image overlay to be drawn at this location."))

;; TODO define-method import-region (does not clone)

(define-method resize-to-background world ()
  (with-fields (background tile-size height width) self
    (assert (stringp background))
    (let ((image (find-resource-object background)))
      (setf height (truncate (/ (image-height background) tile-size)))
      (setf width (truncate (/ (image-width background) tile-size))))
    (/create-default-grid self)))

(define-method location-name world ()
  "Return the location name."
  <name>)
     
(define-method environment-at world (row column)
  (aref <environment-grid> row column))

(define-method environment-condition-at world (row column condition)
  (field-value condition (aref <environment-grid> row column)))

(define-method set-environment-condition-at world (row column condition value)
  (setf (field-value condition 
		     (aref <environment-grid> row column))
	value))

;;; LOGO-like level generation capabilities 

;; Use turtle graphics to generate levels! One may write turtle
;; programs by hand, or use context-free grammars to generate the
;; turtle commands, or generate them programmatically in other ways.
;; See also grammars.lisp.

(define-method generate world (&rest parameters)
  "Generate a world, reading generation parameters from the plist
PARAMETERS and interpreting the world's grammar field <GRAMMAR>."
  (declare (ignore parameters))
  (with-fields (grammar stack) self
    (setf xe2:*grammar* grammar)
    (let ((program (generate 'world)))
      (or program (message "WARNING: Nothing was generated from this grammar."))
      (message (prin1-to-string program))
      (unless <grid>
	(/create-default-grid self))
      (dolist (op program)
	(typecase op
	  (keyword (if (clon:has-method op self)
		       (send nil op self)
		       (message "WARNING: Found keyword without corresponding method in turtle program.")))
	  (symbol (when (null (keywordp op))
		    (when (boundp op)
		      (push (symbol-value op) stack))))
	  (string (push op stack))
	  (number (push op stack)))))))

(define-method is-generated world ()
  (if <grid> t nil))

(define-method generate-with world (parameters)
  (apply #'send self :generate self parameters))

(define-method origin world ()
  "Move the turtle to its default location (0,0) and orientation (east)."
  (setf <row> 0 <column> 0 <direction> :east))

(define-method color world ()
  "Set the color to =FOO= where FOO is the prototype symbol on top of
the stack."
  (let ((prototype (pop <stack>)))
    (if (clon:object-p prototype)
	(setf <paint> prototype)
	(error "Must pass a =FOO= prototype symbol as a COLOR."))))

(define-method push-color world ()
  "Push the symbol name of the current <paint> object onto the stack."
  (clon:with-fields (paint stack) self
      (if (clon:object-p paint)
	  (prog1 (message "PUSHING PAINT ~S" (clon:object-name paint))
	    (push paint stack))
	  (error "No paint to save on stack during PUSH-COLOR."))))

(define-method drop world ()
  "Clone the current <paint> object and drop it at the current turtle
location."
  (clon:with-field-values (paint row column) self
    (if (clon:object-p paint)
	(/drop-cell self (clone paint) row column)
	(error "Nothing to drop. Use =FOO= :COLOR to set the paint color."))))

(define-method jump world ()
  "Jump N squares forward where N is the integer on the top of the stack."
  (let ((distance (pop <stack>)))
    (if (integerp distance)
	(multiple-value-bind (row column) 
	    (step-in-direction <row> <column> <direction> distance)
	  (setf <row> row <column> column)
	  (when (not (array-in-bounds-p <grid> row column))
	    (message "Turtle left drawing area during MOVE.")))
	(error "Must pass an integer as distance for MOVE."))))
      
(define-method draw world ()
  "Move N squares forward while painting cells. Clones N cells where N
is the integer on the top of the stack."
  (clon:with-fields (paint stack) self
    (if (not (clon:object-p paint))
	(error "No paint set.")
	(let ((distance (pop stack)))
	  (if (integerp distance)
	      (dotimes (n distance)
		(/drop-cell self (clone paint) <row> <column>)
		(multiple-value-bind (row column) 
		    (step-in-direction <row> <column> <direction>)
		  (setf <row> row <column> column)
		  (when (array-in-bounds-p <grid> row column)
		      (message "Turtle left drawing area during DRAW."))))
	      (error "Must pass an integer as distance for DRAW."))))))

(define-method pushloc world ()
  "Push the current row,col location (and direction) onto the stack."
  (push (list <row> <column> <direction>) <stack>))

(define-method poploc world ()
  "Jump to the location on the top of the stack, and pop the stack."
  (let ((loc (pop <stack>)))
    (if (and (listp loc) (= 3 (length loc)))
	(destructuring-bind (r c dir) loc
	  (setf <row> r <column> c <direction> dir))
	(error "Invalid location argument for POPLOC. Must be a list of two integers plus a keyword."))))

(define-method right world ()
  "Turn N degrees clockwise, where N is 0, 45, or 90."
  (with-fields (direction stack) self
    (labels ((turn45 () (setf direction (getf *right-turn* direction))))
      (ecase (pop stack)
	(0 nil)
	(45 (turn45))
	(90 (turn45) (turn45))))))

(define-method left world ()
  "Turn N degrees counter-clockwise, where N is 0, 45, or 90."
  (with-fields (direction stack) self
    (labels ((turn45 () (setf direction (getf *left-turn* direction))))
      (ecase (pop stack)
	(0 nil)
	(45 (turn45))
	(90 (turn45) (turn45))))))

(define-method noop world ()
  nil)

(define-method set-narrator world (narrator)
  (setf <narrator> narrator))

(define-method set-browser world (browser)
  (setf <browser> browser))

(define-method random-place world (&optional &key avoiding distance)
  (clon:with-field-values (width height) self
    (let ((limit 10000)
	  (n 0)
	  found r c)
      (loop do (progn (setf r (random height))
		      (setf c (random width))
		      (incf n)
		      (unless 
			  (or (and (numberp distance)
				   (> distance (distance r c 0 0)))
			      (/category-at-p self r c :exclusive))
			(setf found t)))
	    while (and (not found) 
		       (< n limit)))
      (values r c found))))
		      
(define-method drop-sprite world (sprite x y &key no-collisions loadout)
  "Add a sprite to the world. When NO-COLLISIONS is non-nil, then the
object will not be dropped when there is an obstacle. When LOADOUT is
non-nil, the :loadout method is invoked on the sprite after
placement."
  (assert (eq :sprite (field-value :type sprite)))
  (/add-sprite self sprite)
  (/update-position sprite x y)
  (when loadout
    (/loadout sprite))
  (unless no-collisions
    ;; TODO do collision test
    nil))

(define-method drop-cell world (cell row column 
				     &optional &key 
				     loadout no-stepping no-collisions (exclusive t) (probe t))
  "Put the cell CELL on top of the stack of cells at ROW,
COLUMN. If LOADOUT is non-nil, then the `loadout' method of the
dropped cell is invoked after dropping. If the field <auto-loadout> is
non-nil in the CELL, then the `loadout' method is invoked regardless
of the value of LOADOUT.

If NO-COLLISIONS is non-nil, then an object is not dropped on top of
an obstacle. If EXCLUSIVE is non-nil, then two objects with
category :exclusive will not be placed together. If PROBE is non-nil,
try to place the cell in the immediate neighborhood.  Return T if a
cell is placed; nil otherwise."
  (let ((grid <grid>)
	(tile-size <tile-size>)
	(auto-loadout (field-value :auto-loadout cell)))
    (declare (optimize (speed 3)) 
	     (type (simple-array vector (* *)) grid)
	     (fixnum tile-size row column))
    (when (array-in-bounds-p grid row column)
      (ecase (field-value :type cell)
	(:cell
	   (labels ((drop-it (row column)
		      (prog1 t
			(vector-push-extend cell (aref grid row column))
			(setf (field-value :row cell) row)
			(setf (field-value :column cell) column)
			(when (or loadout auto-loadout)
			  (/loadout cell))
			(unless no-stepping
			  (/step-on-current-square cell)))))
	     (if (or no-collisions exclusive)
		 (progn 
		   (when no-collisions
		     (when (not (/obstacle-at-p self row column))
		       (drop-it row column)))
		   (when exclusive
		     (if (/category-at-p self row column :exclusive)
			 (when probe
			   (block probing
			     (dolist (dir *compass-directions*)
			       (multiple-value-bind (r c) 
				   (step-in-direction row column dir)
				 (when (not (/category-at-p self row column :exclusive))
				   (return-from probing (drop-it r c)))))))
			 (drop-it row column))))
		 (drop-it row column))))
	;; handle sprites
	(:sprite
	   (/add-sprite self cell)
	   (/update-position cell 
			    (* column tile-size)
			    (* row tile-size)))))))
  
(define-method drop-player-at-entry world (player)
  "Drop the PLAYER at the first entry point."
  (with-field-values (width height grid tile-size) self
    (multiple-value-bind (dest-row dest-column)
	(block seeking
	  (dotimes (i height)
	    (dotimes (j width)
	      (when (/category-at-p self i j :player-entry-point)
		(return-from seeking (values i j)))))
	  (return-from seeking (values 0 0)))
      (setf <player> player)
      (ecase (field-value :type player)
	(:cell (/drop-cell self player dest-row dest-column :no-stepping t))
	(:sprite (/drop-sprite self player 
			      (* dest-column tile-size)
			      (* dest-row tile-size)))))))
			      
(define-method drop-player-at-last-location world (player)
  (setf <player> player)
  (/drop-cell self player <player-exit-row> <player-exit-column>))
  
(define-method get-player world ()
  <player>)

(define-method loadout-all world ()
  (with-field-values (height width grid) self
    (dotimes (i height)
      (dotimes (j width) 
	(do-cells (cell (aref grid i j))
	  (when (has-method :loadout cell)
	    (/loadout cell)))))))

(define-method player-row world ()
  "Return the grid row the player is on."
  (clon:with-field-values (player tile-size) self
    (ecase (field-value :type player)
      (:sprite (truncate (/ (field-value :y player) tile-size))) 
      (:cell (field-value :row player)))))

(define-method player-column world ()
  "Return the grid column the player is on."
  (clon:with-field-values (player tile-size) self
    (ecase (field-value :type player)
      (:sprite (truncate (/ (field-value :x player) tile-size))) 
      (:cell (field-value :column player)))))

(define-method exit world ()
  "Leave the current world."
  (setf <exited> t) ;; see also `forward' method
  ;; record current location so we can exit back to it
  (setf <player-exit-row> (field-value :row <player>))
  (setf <player-exit-column> (field-value :column <player>))
  (/exit <player>)
  (/delete-cell self <player> <player-exit-row> <player-exit-column>))
  
(define-method obstacle-at-p world (row column)
  "Returns non-nil if there is any obstacle in the grid at ROW, COLUMN."
  (or (not (array-in-bounds-p <grid> row column))
      (some #'(lambda (cell)
		(when (/in-category cell :obstacle)
		  cell))
	    (aref <grid> row column))))

(define-method enemy-at-p world (row column)
  (/category-at-p self row column :enemy))

;; (define-method category-at-xy-p world (x y category)
;;   (let ((

(define-method direction-to-player world (row column)
  "Return the general compass direction of the player from ROW, COLUMN."
  (direction-to row column 
		(/player-row self)
		(/player-column self)))

(define-method distance-to-player world (row column)
  "Return the straight-line distance to the player from ROW, COLUMN."
  (distance row column
	    (/player-row self)
	    (/player-column self)))
	    
(define-method adjacent-to-player world (row column)
  "Return non-nil when ROW, COLUMN is adjacent to the player."
  (<= (/distance-to-player self row column) 1.5))
	
(define-method obstacle-in-direction-p world (row column direction)
  "Return non-nil when there is an obstacle one step in DIRECTION from ROW, COLUMN."
  (multiple-value-bind (nrow ncol)
      (step-in-direction row column direction)
    (/obstacle-at-p self nrow ncol)))

(define-method category-in-direction-p world (row column direction category)
  "Return non-nil when there is a cell in CATEGORY one step in
DIRECTION from ROW, COLUMN. CATEGORY may be a list as well."
  (multiple-value-bind (nrow ncol)
      (step-in-direction row column direction)
    (/category-at-p self nrow ncol category)))

(define-method target-in-direction-p world (row column direction)
  "Return non-nil when there is a target one step in DIRECTION from ROW, COLUMN."
  (multiple-value-bind (nrow ncol)
      (step-in-direction row column direction)
    (/category-at-p self nrow ncol :target)))

(define-method set-player world (player)
  "Set PLAYER as the player object to which the World will forward
most user command messages. (See also the method `forward'.)"
  (setf <player> player))

(define-method resolve-receiver world (receiver)
  (case receiver
    (:world self)
    (:browser <browser>)
    (:narrator <narrator>)
    (:viewport <viewport>)
    (:player <player>)))

(define-method process-messages world ()
  "Process, narrate, and send all the messages in the queue.
The processing step allows the sender to specify the receiver
indirectly as a keyword symbol (like `:world', `:player', or
`:output'.) Any resulting queued messages are processed and sent, and
so on, until no more messages are generated."
  (let ((player <player>))
    (with-message-queue <message-queue> 
      (loop while (queued-messages-p) do
	   (destructuring-bind (sender method-key receiver args)
	       (unqueue-message)
	     (let ((rec (or (/resolve-receiver self receiver) 
			    receiver)))
	       ;; (when (and <narrator> 
	       ;; 		  ;; only narrate player-related messages
	       ;; 		  (or (eq player sender)
	       ;; 		      (eq player rec)))
	       ;; 	 ;; now print message
	       ;; 	 (when (not (zerop (field-value :verbosity <narrator>)))
	       ;; 	   (/narrate-message <narrator> sender method-key rec args)))
	       ;; stop everything if player dies
					;(when (not (/in-category player :dead))
	       ;;
	       ;; don't blow up when no narrator, etc
	       ;; (if (not (clon:object-p receiver))
	       ;; 	   (message "Warning: null receiver in message processing. ~S" 
	       ;; 		    (list (object-name (object-parent sender)) method-key rec))
		   (apply #'send sender method-key rec args)))))))

(define-method get-phase-number world ()
  <phase-number>)

(define-method forward world (method-key &rest args)
  "Send unhandled messages to the player object."
  (assert <player>)
  (when (or (eq :quit method-key) 
	    (not <paused>))
    (prog1 nil
      (let ((player <player>)
	    (phase-number <phase-number>))
	(with-message-queue <message-queue> 
	  (when <narrator> 
	    (/narrate-message <narrator> nil method-key player args))
	  ;; run the player
	  (/run player)
	  ;; send the message to the player, possibly generating queued messages
	  (apply #'send self method-key player args)
	  ;; process any messages that were generated
	  (/process-messages self))))))

(define-method run-cpu-phase-maybe world ()
    "If this is the player's last turn, run the cpu phase. otherwise,
stay in player phase and exit. Always runs cpu when the engine is in
realtime mode."
    (when (or *timer-p* (not (/can-act <player> <phase-number>)))
      (/end-phase <player>)
      (unless <exited>
	(incf <phase-number>)
	(when (not (/in-category <player> :dead))
	  (/run-cpu-phase self))
	(/begin-phase <player>))))

(define-method run-cpu-phase world (&optional phase-p)
  "Run all non-player actor cells."
  (declare (optimize (speed 3)))
  (when (not <paused>)
    (when phase-p
      (incf <phase-number>))
    (with-message-queue <message-queue> 
    (when *mission*
      (/run *mission*))
      (let ((cell nil)
	    (phase-number <phase-number>)
	    (player <player>)
	    (grid <grid>)
	    (categories nil))
	(declare (type (simple-array vector (* *)) grid))
	(/run player) 
	(/clear-light-grid self)
	(/clear-sprite-grid self)
	(dotimes (i <height>)
	  (dotimes (j <width>)
	    (let ((cells (aref grid i j)))
	      (declare (vector cells))
	      (dotimes (z (fill-pointer cells))
		(setf cell (aref cells z))
		(setf categories (field-value :categories cell))
		;; perform lighting
		(when (or (member :player categories)
			  (member :light-source categories))
		  (/render-lighting self cell))
		;; (when (member :player categories)
		;;   (/do-phase cell))
		(when (and (not (eq player cell))
			   (member :actor categories)
			   (not (member :dead categories)))
		  (/begin-phase cell)
		  ;; do cells
		  (loop while (/can-act cell phase-number) do
			(/run cell)
			(/process-messages self)
			(/end-phase cell)))))))
	;; run sprites
	(dolist (sprite <sprites>)
	  (/begin-phase sprite)
	  (loop while (/can-act sprite phase-number) do
		(/run sprite)
		(/process-messages self)
		(/end-phase sprite)))
	;; do sprite collisions
	(when <sprite-table>
	  (/collide-sprites self))))))

(defvar *lighting-hack-function* nil)
  
(define-method render-lighting world (cell)
  "When lighting is activated, calculate lit squares using light
sources and ray casting."
  (let* ((light-radius (field-value :light-radius cell))
	 (ambient <ambient-light>)
	 (light-grid <light-grid>)
	 (grid <grid>)
	 (source-row (field-value :row cell))
	 (source-column (field-value :column cell))
	 (total (+ light-radius 
		   (if (numberp ambient) ambient 0)))
	 (octagon (make-array 100 :initial-element nil :adjustable t :fill-pointer 0))
	 (line (make-array 100 :initial-element nil :adjustable t :fill-pointer 0)))
    (declare (type (simple-array vector (* *)) grid) (optimize (speed 3)))
    ;; don't bother lighting if everything is lit.
    (when (not (eq :total ambient))
      ;; draw only odd-radius octagons that have a center pixel
      (when (evenp total)
	(incf total))
      (labels ((light-square (row column)
		 (when (array-in-bounds-p light-grid row column)
		   (setf (aref light-grid row column) 1) nil))
	       (collect-line-point (x y)
		 (prog1 nil (vector-push-extend (list x y) line)))
		 ;; (if (array-in-bounds-p light-grid x y)
		 ;;     (prog1 nil (vector-push-extend (list x y) line))
		 ;;     t))
	       (make-line (row column)
		 (setf (fill-pointer line) 0)
		 (let ((flipped (trace-line #'collect-line-point 
					    source-column source-row
					    column row)))
		   ;; Bresenham's swaps the input points around when x0 is to the
		   ;; right of x1. We need to reverse the list of points if this
		   ;; happens, otherwise shadows will be cast the wrong way.
		   (if flipped
		       (setf line (nreverse line))
		       ;; Furthermore, when a non-flipped line is drawn, the endpoint 
		       ;; isn't actually visited, so we append it to the list. (Maybe this 
		       ;; is a bug in my implementation?)
		       ;;
		       ;; Make sure endpoint of ray is traced.
		       (when (array-in-bounds-p grid row column)
			 (vector-push-extend (list row column) line)))))
	       (light-line (row column)
		 (make-line row column)
		 (block lighting 
		   (dotimes (i (fill-pointer line))
		     do (destructuring-bind (r c) (aref line i)
			  (when (array-in-bounds-p grid r c)
			    (light-square r c)
			    ;; HACK
			    (when *lighting-hack-function*
			      (funcall *lighting-hack-function* 
				       source-row source-column
				       r c))
			    ;; should we stop lighting?
			    (when (/category-at-p self r c :opaque) ;;'(:opaque :obstacle))
			      (return-from lighting t)))))))
	       (collect-octagon-point (r c)
		 (vector-push-extend (list r c) octagon) nil)
	       (light-rectangle (row column radius)
		 (trace-rectangle #'light-square 
				  (- row radius)
				  (- column radius) 
				  (* 2 radius)
				  (* 2 radius)
				  :fill))
	       (light-octagon (row column radius)
		 (setf (fill-pointer octagon) 0)
	       	 (trace-octagon #'collect-octagon-point 
	       			row column radius :thicken)
	       	 (dotimes (i (fill-pointer octagon))
	       	   (destructuring-bind (row column) (aref octagon i)
		     ;; HACK
		     ;; (when *lighting-hack-funtcion*
		     ;;   (funcall *lighting-hack-function* 
		     ;; 		source-row source-column
		     ;; 		row column ".red"))
	       	     (light-line row column)))))
	(light-octagon source-row source-column total)
	(light-octagon source-row source-column (- total 2))))))

(define-method clear-light-grid world ()
  (unless <automapped>
    (let ((light-grid <light-grid>))
      (dotimes (i <height>)
	(dotimes (j <width>)	
	  (setf (aref light-grid i j) 0))))))

(define-method begin-ambient-loop world ()
  "Begin looping your music for this world here."
  nil)

(define-method describe world (&optional description)
  (setf description (or description <description>))
  (if (stringp description)
      (dolist (line (split-string-on-lines description))
	(/>>narrateln :narrator line))
      ;; it's a formatted string
      (dolist (line description)
	(dolist (string line)
	  (apply #'send-queue nil :print :narrator string))
	(send-queue nil :newline :narrator)
	(send-queue nil :newline :narrator))))

(define-method start world ()
  "Prepare the world for play."
  (assert <player>)
  ;; start player at same phase (avoid free catch-up turns)
  ;; get everyone on the same turn, and start 'er up
  (setf <phase-number> (+ 1 (field-value :phase-number <player>)))
  (let ((grid <grid>)
	(phase-number <phase-number>))
    (dotimes (i <height>)
      (dotimes (j <width>)
	(do-cells (cell (aref grid i j))
	  (setf (field-value :phase-number cell) phase-number)
	  (unless (/is-player cell) (/start cell))))))
  (dolist (sprite <sprites>)
    (setf (field-value :phase-number sprite) <phase-number>))
  ;; mark the world as entered
  (setf <exited> nil)
  ;; light up the world
  (/render-lighting self <player>)
  ;; clear out any pending messages
  (setf <message-queue> (make-queue))
  (with-message-queue <message-queue>
    (/run-cpu-phase self)
    (incf <phase-number>)
    (/start <player>)
    (/begin-phase <player>)
    ;; (when (has-method :show-location <player>)
    ;;   (/show-location <player>))
    (/after-start-method self)
    (/process-messages self))
  ;; get player onscreen
  (when <viewport> (/adjust <viewport> :snap))
  (/begin-ambient-loop self))

(define-method after-start-method world ()
  nil)
    
(define-method set-viewport world (viewport)
  "Set the viewport widget."
  (setf <viewport> viewport))
	
(define-method line-of-sight world (r1 c1 r2 c2 &optional (category :obstacle))
  "Return non-nil when there is a direct Bresenham's line of sight
along grid squares between R1,C1 and R2,C2."
  (let ((grid <grid>))
    (when (and (array-in-bounds-p grid r1 c1) 
	       (array-in-bounds-p grid r2 c2))
      (let ((line (make-array 100 :initial-element nil :adjustable t :fill-pointer 0))
	    (num-points 0)
	    (r0 r1)
	    (c0 c1))
	(labels ((collect-point (&rest args)
		   (prog1 nil
		     (vector-push-extend args line)
		     (incf num-points))))
	  (let ((flipped (trace-line #'collect-point c1 r1 c2 r2)))
	    (if flipped 
		(setf line (nreverse line))
		(when (array-in-bounds-p grid r2 c2)
		  (incf num-points)
		  (vector-push-extend (list c2 r2) line)))
	    (let ((retval (block tracing
			    (let ((i 0))
			      (loop while (< i num-points) do
				(destructuring-bind (x y) (aref line i)
				  (setf r0 x c0 y)
				  (when *lighting-hack-function* 
				    (funcall *lighting-hack-function* r0 c0 r1 c1))
				  (if (and (= r0 r2)
					   (= c0 c2))
				      (return-from tracing t)
				      (when (/category-at-p self r0 c0 category)
					(return-from tracing nil))))
				(incf i)))
			    (return-from tracing t))))
	      (prog1 retval nil))))))))

;;; The sprite layer. See also viewport.lisp

(define-method add-sprite world (sprite)
  (pushnew sprite <sprites> :test 'equal))

(define-method remove-sprite world (sprite)
  (setf <sprites> (delete sprite <sprites>)))

(define-method clear-sprite-grid world ()
  (let ((grid <sprite-grid>))
    (dotimes (i <height>)
      (dotimes (j <width>)
	(setf (fill-pointer (aref grid i j)) 0)))))

(define-method collide-sprites world (&optional sprites)
  "Perform collision detection between sprites and the grid.
Sends a :do-collision message for every detected collision."
  (with-field-values (width height tile-size sprite-grid sprite-table grid) self
    (dolist (sprite (or sprites <sprites>))
      
      ;; figure out which grid squares we really need to scan
      (let* ((x (field-value :x sprite)) 
	     (y (field-value :y sprite)) 
	     (left (1- (floor (/ x tile-size))))
	     (right (1+ (floor (/ (+ x (field-value :width sprite)) tile-size))))
	     (top (1- (floor (/ y tile-size))))
	     (bottom (1+ (floor (/ (+ y (field-value :height sprite)) tile-size)))))
	;; find out which scanned squares actually intersect the sprite
;;	(message "COLLIDE-SPRITES DEBUG: ~S" (list x y left right top bottom))
	(block colliding
	  (dotimes (i (max 0 (- bottom top)))
	    (dotimes (j (max 0 (- right left)))
	      (let ((i0 (+ i top))
		    (j0 (+ j left)))
		(when (array-in-bounds-p grid i0 j0)
		  (when (/collide-* sprite 
				   (* i0 tile-size) 
				   (* j0 tile-size)
				   tile-size tile-size)
		    ;; save this intersection information
		    (vector-push-extend sprite (aref sprite-grid i0 j0))
		    ;; collide the sprite with the cells on this square
		    (do-cells (cell (aref grid i0 j0))
		      (when (and (or (/in-category cell :target)
				     (/in-category cell :obstacle))
				 (/is-located cell))
			(/do-collision sprite cell)))))))))))
    ;; now find collisions with other sprites
    ;; we can re-use the sprite-grid data from earlier.
    (let (collision num-sprites ix)
      ;; prepare to detect redundant collisions
      (clrhash sprite-table)
      (labels ((collide-first (&rest args)
		 (unless (gethash args sprite-table)
		   (setf (gethash args sprite-table) t)
		   (destructuring-bind (a b) args
		     (/do-collision a b)))))
	;; iterate over grid, reporting collisions
	(dotimes (i height)
	  (dotimes (j width)
	    (setf collision (aref sprite-grid i j))
	    (setf num-sprites (length collision))
	    (when (< 1 num-sprites)
	      (dotimes (i (- num-sprites 1))
		(setf ix (1+ i))
		(loop do (let ((a (aref collision i))
			       (b (aref collision ix)))
			   (incf ix)
			   (assert (and (clon:object-p a) (clon:object-p b)))
			   (when (and (not (eq a b)) (/collide a b))
			     (collide-first a b)))
		      while (< ix num-sprites))))))))))

;;; Universes are composed of connected worlds.

(defvar *universe* nil)

(defun normalize-address (address)
  "Sort the plist ADDRESS so that its keys come in alphabetical order
by symbol name. This enables them to be used as hash keys."
  (etypecase address
    (string address)
    (list (assert (and (symbolp (first address))
		       (or (null (rest address))
			   (keywordp (second address)))))
       (labels ((all-keys (plist)
		  (let (keys)
		    (loop while (not (null plist))
			  do (progn (push (pop plist) keys)
				    (pop plist)))
		    keys)))
	 (let (address2)
	   (dolist (key (sort (all-keys (cdr address)) #'string> :key #'symbol-name))
	     ;; build sorted plist
	     (push (getf (cdr address) key) address2)
	     (push key address2))
	   (cons (car address) address2))))))

(defparameter *default-space-size* 10)

(define-prototype universe 
    (:documentation "A collection of connected worlds.")
  (worlds :initform (make-hash-table :test 'equal)
	  :documentation "Address-to-world mapping.")
  prompt
  (viewport :initform nil)
  (current-address :initform nil)
  (player :initform nil)
  (stack :initform '())
  (space :initform nil 
	 :documentation "When non-nil, this vector of worlds
represents the z-axis of a euclidean 3-D space."))

(define-method make-euclidean universe ()
  (setf <space> (make-array *default-space-size* 
			    :adjustable t
			    :fill-pointer 0)))

(define-method get-space-at universe (index)
  (aref <space> index))

(define-method set-space-at universe (index world)
  (setf (aref <space> index) world))

(define-method get-next-space universe (index)
  (incf index)
  (when (and (<= 0 index)
	     (< index (fill-pointer <space>)))
    (aref <space> index)))

(define-method get-previous-space universe (index)
  (decf index)
  (when (and (<= 0 index)
	     (< index (fill-pointer <space>)))
    (aref <space> index)))

(define-method add-world universe (address world)
  (setf (gethash (normalize-address address) <worlds>) world))
 
(define-method remove-world universe (address)
  (remhash (normalize-address address) <worlds>))

(define-method get-world universe (address)
  (gethash (normalize-address address) <worlds>))

(define-method get-player universe ()
  <player>)

(define-method set-player universe (player)
  (setf <player> player))

(define-method get-current-world universe ()
  (car <stack>))

(define-method get-current-address universe ()
  <current-address>)

(define-method destroy universe ()
  (setf <worlds> (make-hash-table :test 'equal))
  (setf <stack> nil)
  (setf <current-address> nil))

(define-method generate-world universe (address)
  (destructuring-bind (prototype &rest parameters) address
    (let ((world (clone (symbol-value prototype))))
      (prog1 world
	;; make sure any loadouts or intializers get run with the proper world
	(let ((*world* world)) 
	  (/generate-with world parameters))))))

(define-method find-world universe (address)
  (assert address)
  (let ((candidate (/get-world self address)))
    (if (null candidate)
	(/add-world self (normalize-address address)
		   (if (stringp address)
		       (find-resource-object address)
		       (/generate-world self address)))
	candidate)))

(define-method configure universe (&key address player prompt narrator viewport)
  (when address (setf <current-address> address))
  (when player (setf <player> player))
  (when prompt (setf <prompt> prompt))
  (when narrator (setf <narrator> narrator))
  (when viewport (setf <viewport> viewport)))

(define-method play universe (&key address player prompt narrator viewport)
  "Prepare a universe for play at the world identified by ADDRESS with
PLAYER as the player, PROMPT as the prompt, NARRATOR as the
narrator, and VIEWPORT as the viewport."
  (when address (setf <current-address> address))
  (when player (setf <player> player))
  (when prompt (setf <prompt> prompt))
  (when narrator (setf <narrator> narrator))
  (when viewport (setf <viewport> viewport))
  (assert (and <prompt> <narrator>))
  (let ((world (/find-world self <current-address>))
	(player <player>)
	(previous-world (car <stack>)))
    ;; make sure exit coordinates are saved, so we can go back to this point
    (when previous-world 
      (/exit previous-world))
    ;; make the new world the current world
    (push world <stack>)
    (setf *world* world)
    (setf *universe* self)
    (/set-viewport world <viewport>)
    (/set-world <viewport> world)
    (/drop-player-at-entry world player)
    (/set-receiver <prompt> world)
    (/set-narrator world <narrator>)
    (/start world)))

(define-method exit universe (&key player)
  "Return the player to the previous world on the stack."
  (when player (setf <player> player))
  (with-fields (stack) self
    ;; exit and discard current world
    (/exit (pop stack))
    ;; 
    (let ((world (car stack)))
      (if world
	  (progn (setf *world* world)
		 (setf *universe* self)
		 ;; resume at previous play coordinates
		 (/drop-player-at-last-location world <player>)
		 (/start world)
		 (/set-receiver <prompt> world)
		 (/set-world <viewport> world)
		 (/set-narrator world <narrator>)
		 (/set-viewport world <viewport>)
		 (/set-player world <player>))
	  (error "No world.")))))

;;; Gateways and launchpads connect worlds together

(defcell gateway
  (tile :initform "gateway")
  (name :initform "Gateway")
  (categories :initform '(:gateway))
  (destination :initform nil))

(define-method initialize gateway (&key destination tile name)
  (when tile (setf <tile> tile))
  (when name (setf <name> name))
  (when destination (setf <destination> destination)))

(define-method activate gateway ()
  (with-fields (destination) self
    (etypecase destination
      ;; it's an address.
      (list (/play *universe* :address destination))
      ;; it's a mission name
      (symbol (/begin (symbol-value destination) (/get-player *world*))))))
	 
(define-prototype launchpad (:parent =gateway=)
  (tile :initform "launchpad")
  (categories :initform '(:gateway :player-entry-point))
  (description :initform "Press RETURN here to exit this area."))

(define-method activate launchpad ()
  (/exit *universe* :player (/get-player *world*)))

(define-method drop-entry-point world (row column)
  (/replace-cells-at self row column (clone =launchpad=)))

;;; Convenience macro for defining worlds:

(defmacro defworld (name &body args)
  "Define a world named NAME, with the fields ARGS as in a normal
prototype declaration. This is a convenience macro for defining new
worlds."
  `(define-prototype ,name (:parent =world=)
     ,@args))

;;; worlds.lisp ends here
