(in-package :blast)

;;; Strength powerup

(defcell level-up 
  (categories :initform '(:item))
  (tile :initform "levelup")
  (name :initform "Strength power-up")
  (description :initform "Permanently boost your strength."))

(define-method step level-up (stepper)
  (when [is-player stepper] 
    (play-sample "worp")
    [>>say :narrator "LEVEL UP! Max hit points +4"]
    [>>stat-effect stepper :hit-points 4 :max]
    [>>stat-effect stepper :strength 2]
    [>>die self]))

;;; Speed powerup

(defcell speed-up 
  (categories :initform '(:item))
  (tile :initform "speedup")
  (name :initform "Speed power-up")
  (description :initform "Permanently boost your speed.")) 

(define-method step speed-up (stepper)
  (when [is-player stepper]
    (play-sample "worp")
    [>>say :narrator "SPEED +2!"]
    [>>stat-effect stepper :speed 2]
    [>>die self]))

(defun random-stat-powerup ()
  (clone (case (random 2)
	   (0 =level-up=)
	   (1 =speed-up=))))

;;; There are also energy tanks for replenishing ammo.

(defcell energy 
  (tile :initform "energy")
  (description :initform 
"Refills part of your energy store, for energy ammo weapons."))

(define-method step energy (stepper)
  (when [is-player stepper]
    (when (has-field :energy stepper)
      [play-sample self "whoop"]
      [>>stat-effect stepper :energy 7]
      [>>die self])))

;;; A life powerup.

(defcell diamond
  (tile :initform "diamond")
  (description :initform "Restore some hit points to a human."))

(define-method step diamond (stepper)
  (if (and [is-player stepper]
	   (eq :spacesuit (field-value :mode stepper)))
      (progn [say self "You recover some health from the health-pak."]
	     [play-sample self "powerup"]
	     [stat-effect stepper :hit-points 8]
	     [die self])
      [say self "You cannot use this health-pak while in a vehicle."]))

;;; Endurium crystals to collect.

(defcell crystal
  (tile :initform "crystal")
  (categories :initform '(:target :endurium))
  (hit-points :initform (make-stat :base 1 :min 0))
  (description :initform "A one-kilogram chunk of endurium. Highly fragile."))

(define-method step crystal (stepper)
  (when [is-player stepper]
   [play-sample self "bip"]
   [stat-effect stepper :endurium 1]
   [stat-effect stepper :score 1000]
   [die self]))

(defcell big-crystal
  (tile :initform "big-crystal")
  (categories :initform '(:endurium))
  (hit-points :initform (make-stat :base 2 :min 0))
  (description :initform "A massive chunk of endurium. Highly fragile."))

(define-method step big-crystal (stepper)
  (when [is-player stepper]
   [play-sample self "bip"]
   [stat-effect stepper :endurium 10]
   [stat-effect stepper :score 10000]
   [die self]))

(defcell small-crystal 
  (tile :initform "small-crystal")
  (categories :initform '(:endurium))
  (description :initform "Fragments of valuable endurium."))

(define-method step small-crystal (stepper)
  (when [is-player stepper]
   [play-sample self "bip"]
   [stat-effect stepper :endurium 0.3]
   [stat-effect stepper :score 100]
   [die self]))

;;; A trail extender powerup.

(defcell extender 
  (tile :initform "plus")
  (description :initform "Extends Olvac-3 trail."))

(define-method step extender (stepper)
  (when [is-player stepper]
    [play-sample self "powerup"]
    [>>say :narrator "Trail extend!"]
    [stat-effect stepper :trail-length 4]
    [stat-effect stepper :score 2000]
    [die self]))

;;; Extra ammo for pulse protector

(defcell pulse-ammo 
  (tile :initform "pulse-ammo")
  (description :initform "Ammunition for pulse wave. Press 2 to fire."))

(define-method step pulse-ammo (stepper)
  (when [is-player stepper]
    [play-sample self "powerup"]
    [>>say :narrator "PULSE +2!"]
    [stat-effect stepper :pulse-ammo 2]
    [stat-effect stepper :score 2000]
    [die self]))

;;; Extra bomb ammo

(defcell bomb-ammo
  (tile :initform "bomb-ammo")
  (description :initform "Bomb ammunition, 2 pack."))

(define-method step bomb-ammo (stepper)
  (when [is-player stepper]
    [play-sample self "powerup"]
    [>>say :narrator "BOMB +2!"]
    [stat-effect stepper :bomb-ammo 2]
    [die self]))

;;; Random powerup function

(defun random-powerup ()
  (clone (ecase (random 6)
	   (0 =diamond=)
	   (1 =pulse-ammo=)
	   (2 =extender=)
	   (3 =bomb-ammo=)
	   (4 =diamond=)
	   (5 =mystery-box=))))

;;; Some destructible blocks

(defcell blast-box
  (tile :initform "blast-box")
  (name :initform "Storage crate")
  (categories :initform '(:obstacle :opaque :pushable :destructible :target))
  (hit-points :initform (make-stat :base 1 :min 0)))

(defcell blast-box-debris
  (tile :initform "blast-box-debris")
  (name :initform "Crate debris"))

(define-method die blast-box ()
  [>>drop self (clone =blast-box-debris=)]
  [parent>>die self])

;;; Technetium ore

(defcell technetium 
  (tile :initform "technetium")
  (name :initform "Technetium ore")
  (description :initform 
"This precious mineral is used in the manufacture of metaprocessors."))

(define-method step technetium (stepper)
  (when [is-player stepper]
    (let ((weight (1+ (random 15))))
      [stat-effect stepper :technetium weight]
      [>>say :narrator (format nil "Obtained ~D ug technetium." weight)])
    [play-sample self "technetium-sound"]
    [die self]))

(defcell biosilicate 
  (tile :initform "biosilicate")
  (name :initform "Biosilicate resin")
  (description :initform 
"This resin is harvested from the fruiting bodies and decaying forms
of the Biosilicate races. Thousands of industrial chemical compounds
and materials can be extracted from raw biosilicate resin of various
types."))

(define-method step biosilicate (stepper)
  (when [is-player stepper]
    (let ((weight (1+ (random 15))))
      [stat-effect stepper :biosilicate weight]
      [>>say :narrator (format nil "Obtained ~D ug biosilicate." weight)])
    [play-sample self "biosilicate-sound"]
    [die self]))

;;; The ion shield

(defcell ion-shield-wall 
  (tile :initform "ion-shield-wall")
  (categories :initform '(:obstacle :opaque :actor :target))
  (hit-points :initform (make-stat :base 10 :min 0))
  (clock :initform (+ 12 (random 4)))
  (description :initform "Part of the ion shield wall."))

(define-method die ion-shield-wall ()
  [queue>>drop-cell *active-world* (clone =flash=) <row> <column>]
  [parent>>die self])

(define-method run ion-shield-wall ()
  (when (zerop <clock>)
    [die self])
  (decf <clock>))

(defcell ion-shield 
  (categories :initform '(:item :equipment))
  (name :initform "Ion shield belt")
  (tile :initform "ion-shield")
  (equip-for :initform '(:belt :shoulder-mount :extension))
  (size :initform 5)
  (description :initform 
"This sheld throws up a temporary, stationary barrier against incoming
missiles and enemies."))

(defparameter *ion-shield-energy-cost* 6)

(define-method activate ion-shield ()
  (let* ((world *active-world*)
	 (row [player-row world])
	 (column [player-column world])
	 (size <size>))
    (if [expend-energy <equipper> *ion-shield-energy-cost*]
      (labels ((drop-ion (r c)
		 (prog1 nil
		   [drop-cell world (clone =ion-shield-wall=) r c :no-collisions nil])))
	[>>say :narrator "Activating ion shield."]
	(trace-rectangle #'drop-ion 
			 (- row (truncate (/ size 2)))
			 (- column (truncate (/ size 2)))
			 size size))
      [>>say :narrator "Not enough energy to activate shield."])))

(define-method step ion-shield (stepper)
  (when [is-player stepper]
    [>>say :narrator "You've found the Ion Shield Belt."]
    [equip stepper [take stepper :direction :here :category :item] :extension]))

;;; Powerup mystery box

(defcell mystery-box
  (tile :initform "mystery-box")
  (hit-points :initform (make-stat :base 5 :min 0))
  (categories :initform '(:target))
  (description :initform "Shoot the box for a surprise inside!"))

(define-method die mystery-box ()
  (let ((item (clone (ecase (random 3)
		       (0 =ion-shield=)
		       (1 =diamond=)
		       (2 =energy=)))))
    [drop self item]
    [parent>>die self]))

;;; The exploding mine

(defcell mine 
  (name :initform "Proximity mine")
  (categories :initform '(:item :target :actor :hidden))
  (tile :initform "mine")
  (description :initform "If you get near it, it will probably explode."))

(defvar *mine-warning-sensitivity* 5)
(defvar *mine-explosion-sensitivity* 3)

(define-method run mine ()
  (let ((distance [distance-to-player *active-world* <row> <column>]))
    (if (< distance *mine-warning-sensitivity*)
	(progn
	  (when (string= <tile> "mine")
	    [>>say :narrator "You see a mine nearby!"])
	  (setf <tile> "mine-warn")
	  (when (< distance *mine-explosion-sensitivity*)
	    (when (< (random 8) 1)
	      [explode self])))
	(setf <tile> "mine"))))

(define-method explode mine ()
  (labels ((boom (r c &optional (probability 50))
	     (prog1 nil
	       (when (and (< (random 100) probability)
			  [in-bounds-p *active-world* r c])
		 [drop-cell *active-world* (clone =explosion=) r c :no-collisions nil]))))
    (dolist (dir rlx:*compass-directions*)
      (multiple-value-bind (r c)
	  (step-in-direction <row> <column> dir)
	(boom r c 100)))
    ;; randomly sprinkle some fire around edges
    (trace-rectangle #'boom 
		     (- <row> 2) 
		     (- <column> 2) 
		     5 5)
    [die self]))

(define-method step mine (stepper)
  (when [is-player stepper]	      
    [explode self]))

(define-method damage mine (damage-points)
  (declare (ignore damage-points))
  [explode self])
  
;;; Visible chain mines

(define-prototype contact-mine (:parent =mine=)
  (name :initform "Contact mine")
  (tile :initform "minesweeper")
  (descriptions :initform "Contact mines explode... um, on contact."))

(define-method run mine ()
  nil)


