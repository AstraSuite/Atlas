//! CircularIndicatorManager: the Material 3 indeterminate spinner geometry
//! that CircularIndicator.qml animates.

#[cxx_qt::bridge]
pub mod qobject {
    #[qenum(CircularIndicatorManager)]
    enum IndeterminateAnimationType {
        Advance,
        Retreat,
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(f64, start_fraction, cxx_name = "startFraction", READ, NOTIFY = start_fraction_changed)]
        #[qproperty(f64, end_fraction, cxx_name = "endFraction", READ, NOTIFY = end_fraction_changed)]
        #[qproperty(f64, rotation, READ, NOTIFY = rotation_changed)]
        #[qproperty(f64, progress, READ, WRITE = set_progress, NOTIFY = progress_changed)]
        #[qproperty(f64, complete_end_progress, cxx_name = "completeEndProgress", READ, WRITE = set_complete_end_progress, NOTIFY = complete_end_progress_changed)]
        #[qproperty(f64, duration, READ = duration, NOTIFY = indeterminate_animation_type_changed)]
        #[qproperty(f64, complete_end_duration, cxx_name = "completeEndDuration", READ = complete_end_duration, NOTIFY = indeterminate_animation_type_changed)]
        #[qproperty(i32, indeterminate_animation_type, cxx_name = "indeterminateAnimationType", READ, WRITE = set_indeterminate_animation_type, NOTIFY = indeterminate_animation_type_changed)]
        type CircularIndicatorManager = super::CircularIndicatorManagerRust;

        #[qsignal]
        #[cxx_name = "startFractionChanged"]
        fn start_fraction_changed(self: Pin<&mut CircularIndicatorManager>);
        #[qsignal]
        #[cxx_name = "endFractionChanged"]
        fn end_fraction_changed(self: Pin<&mut CircularIndicatorManager>);
        #[qsignal]
        #[cxx_name = "rotationChanged"]
        fn rotation_changed(self: Pin<&mut CircularIndicatorManager>);
        #[qsignal]
        #[cxx_name = "progressChanged"]
        fn progress_changed(self: Pin<&mut CircularIndicatorManager>);
        #[qsignal]
        #[cxx_name = "completeEndProgressChanged"]
        fn complete_end_progress_changed(self: Pin<&mut CircularIndicatorManager>);
        #[qsignal]
        #[cxx_name = "indeterminateAnimationTypeChanged"]
        fn indeterminate_animation_type_changed(self: Pin<&mut CircularIndicatorManager>);

        #[cxx_name = "setProgress"]
        fn set_progress(self: Pin<&mut CircularIndicatorManager>, progress: f64);
        #[cxx_name = "setCompleteEndProgress"]
        fn set_complete_end_progress(self: Pin<&mut CircularIndicatorManager>, progress: f64);
        fn duration(self: &CircularIndicatorManager) -> f64;
        #[cxx_name = "completeEndDuration"]
        fn complete_end_duration(self: &CircularIndicatorManager) -> f64;
        #[cxx_name = "setIndeterminateAnimationType"]
        fn set_indeterminate_animation_type(self: Pin<&mut CircularIndicatorManager>, kind: i32);
    }
}

use cxx_qt::CxxQtType;
use qobject::CircularIndicatorManager;
use std::pin::Pin;

mod advance {
    pub const TOTAL_DURATION_IN_MS: f64 = 5400.0;
    pub const DURATION_TO_EXPAND_IN_MS: f64 = 667.0;
    pub const DURATION_TO_COLLAPSE_IN_MS: f64 = 667.0;
    pub const DURATION_TO_COMPLETE_END_IN_MS: f64 = 333.0;
    pub const TAIL_DEGREES_OFFSET: f64 = -20.0;
    pub const EXTRA_DEGREES_PER_CYCLE: f64 = 250.0;
    pub const CONSTANT_ROTATION_DEGREES: f64 = 1520.0;
    pub const DELAY_TO_EXPAND_IN_MS: [f64; 4] = [0.0, 1350.0, 2700.0, 4050.0];
    pub const DELAY_TO_COLLAPSE_IN_MS: [f64; 4] = [667.0, 2017.0, 3367.0, 4717.0];
}

mod retreat {
    pub const TOTAL_DURATION_IN_MS: f64 = 6000.0;
    pub const DURATION_SPIN_IN_MS: f64 = 500.0;
    pub const DURATION_GROW_ACTIVE_IN_MS: f64 = 3000.0;
    pub const DURATION_SHRINK_ACTIVE_IN_MS: f64 = 3000.0;
    pub const DELAY_SPINS_IN_MS: [f64; 4] = [0.0, 1500.0, 3000.0, 4500.0];
    pub const DELAY_GROW_ACTIVE_IN_MS: f64 = 0.0;
    pub const DELAY_SHRINK_ACTIVE_IN_MS: f64 = 3000.0;
    pub const DURATION_TO_COMPLETE_END_IN_MS: f64 = 500.0;
    pub const CONSTANT_ROTATION_DEGREES: f64 = 1080.0;
    pub const SPIN_ROTATION_DEGREES: f64 = 90.0;
    pub const END_FRACTION_RANGE: [f64; 2] = [0.10, 0.87];
}

const ADVANCE: i32 = 0;

fn fraction_in_range(playtime: f64, start: f64, duration: f64) -> f64 {
    ((playtime - start) / duration).clamp(0.0, 1.0)
}

/// The standard-ish cubic bezier (0.4, 0) (0.2, 1), like the QEasingCurve
/// the C++ version used: solve x(t) = progress, return y(t).
fn ease(progress: f64) -> f64 {
    const P1: (f64, f64) = (0.4, 0.0);
    const P2: (f64, f64) = (0.2, 1.0);
    let bezier = |t: f64, a: f64, b: f64| {
        let u = 1.0 - t;
        3.0 * u * u * t * a + 3.0 * u * t * t * b + t * t * t
    };
    if progress <= 0.0 {
        return 0.0;
    }
    if progress >= 1.0 {
        return 1.0;
    }
    let (mut lo, mut hi) = (0.0, 1.0);
    let mut t = progress;
    for _ in 0..40 {
        let x = bezier(t, P1.0, P2.0);
        if (x - progress).abs() < 1e-7 {
            break;
        }
        if x < progress {
            lo = t;
        } else {
            hi = t;
        }
        t = (lo + hi) / 2.0;
    }
    bezier(t, P1.1, P2.1)
}

fn fuzzy_eq(a: f64, b: f64) -> bool {
    ((a + 1.0) - (b + 1.0)).abs() <= 1e-12 * (a + 1.0).abs().min((b + 1.0).abs())
}

#[derive(Default)]
pub struct CircularIndicatorManagerRust {
    start_fraction: f64,
    end_fraction: f64,
    rotation: f64,
    progress: f64,
    complete_end_progress: f64,
    indeterminate_animation_type: i32,
}

impl CircularIndicatorManager {
    fn duration(&self) -> f64 {
        if self.indeterminate_animation_type == ADVANCE { advance::TOTAL_DURATION_IN_MS } else { retreat::TOTAL_DURATION_IN_MS }
    }

    fn complete_end_duration(&self) -> f64 {
        if self.indeterminate_animation_type == ADVANCE {
            advance::DURATION_TO_COMPLETE_END_IN_MS
        } else {
            retreat::DURATION_TO_COMPLETE_END_IN_MS
        }
    }

    fn set_indeterminate_animation_type(mut self: Pin<&mut Self>, kind: i32) {
        if self.indeterminate_animation_type != kind {
            self.as_mut().rust_mut().indeterminate_animation_type = kind;
            self.indeterminate_animation_type_changed();
        }
    }

    fn set_progress(self: Pin<&mut Self>, progress: f64) {
        self.update(progress);
    }

    fn set_complete_end_progress(mut self: Pin<&mut Self>, progress: f64) {
        if fuzzy_eq(self.complete_end_progress, progress) {
            return;
        }
        self.as_mut().rust_mut().complete_end_progress = progress;
        self.as_mut().complete_end_progress_changed();
        let current = self.progress;
        self.update(current);
    }

    fn update(mut self: Pin<&mut Self>, progress: f64) {
        if fuzzy_eq(self.progress, progress) {
            return;
        }
        if self.indeterminate_animation_type == ADVANCE {
            self.as_mut().update_advance(progress);
        } else {
            self.as_mut().update_retreat(progress);
        }
        self.as_mut().rust_mut().progress = progress;
        self.progress_changed();
    }

    fn update_retreat(mut self: Pin<&mut Self>, progress: f64) {
        use retreat::*;
        let playtime = progress * TOTAL_DURATION_IN_MS;
        let spin: f64 = DELAY_SPINS_IN_MS
            .iter()
            .map(|delay| ease(fraction_in_range(playtime, *delay, DURATION_SPIN_IN_MS)) * SPIN_ROTATION_DEGREES)
            .sum();
        let rotation = CONSTANT_ROTATION_DEGREES * progress + spin;
        let old_rotation = self.rotation;
        self.as_mut().rust_mut().rotation = rotation;
        if !fuzzy_eq(rotation, old_rotation) {
            self.as_mut().rotation_changed();
        }

        let fraction = ease(fraction_in_range(playtime, DELAY_GROW_ACTIVE_IN_MS, DURATION_GROW_ACTIVE_IN_MS))
            - ease(fraction_in_range(playtime, DELAY_SHRINK_ACTIVE_IN_MS, DURATION_SHRINK_ACTIVE_IN_MS));
        if self.start_fraction.abs() > 1e-12 {
            self.as_mut().rust_mut().start_fraction = 0.0;
            self.as_mut().start_fraction_changed();
        }
        let old_end = self.end_fraction;
        let mut end = END_FRACTION_RANGE[0] + (END_FRACTION_RANGE[1] - END_FRACTION_RANGE[0]) * fraction;
        if self.complete_end_progress > 0.0 {
            end *= 1.0 - self.complete_end_progress;
        }
        self.as_mut().rust_mut().end_fraction = end;
        if !fuzzy_eq(end, old_end) {
            self.end_fraction_changed();
        }
    }

    fn update_advance(mut self: Pin<&mut Self>, progress: f64) {
        use advance::*;
        let playtime = progress * TOTAL_DURATION_IN_MS;
        let (old_start, old_end) = (self.start_fraction, self.end_fraction);
        let mut start = CONSTANT_ROTATION_DEGREES * progress + TAIL_DEGREES_OFFSET;
        let mut end = CONSTANT_ROTATION_DEGREES * progress;
        for cycle in 0..4 {
            end += ease(fraction_in_range(playtime, DELAY_TO_EXPAND_IN_MS[cycle], DURATION_TO_EXPAND_IN_MS)) * EXTRA_DEGREES_PER_CYCLE;
            start += ease(fraction_in_range(playtime, DELAY_TO_COLLAPSE_IN_MS[cycle], DURATION_TO_COLLAPSE_IN_MS)) * EXTRA_DEGREES_PER_CYCLE;
        }
        start += (end - start) * self.complete_end_progress;
        start /= 360.0;
        end /= 360.0;
        {
            let mut rust = self.as_mut().rust_mut();
            rust.start_fraction = start;
            rust.end_fraction = end;
        }
        if !fuzzy_eq(start, old_start) {
            self.as_mut().start_fraction_changed();
        }
        if !fuzzy_eq(end, old_end) {
            self.end_fraction_changed();
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn easing_endpoints() {
        assert_eq!(super::ease(0.0), 0.0);
        assert_eq!(super::ease(1.0), 1.0);
        assert!(super::ease(0.5) > 0.5);
    }
}
