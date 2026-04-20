# omems-filters
Equalisation filters, scripts and log files for OMEMS mri earphones

## Update 22/04/2026

The original pair of OMEMS installed in the BUCNI Prisma scanner have now been labelled with additional red stickers marked "OLD". A new pair of OMEMS has also been added to the scanner equipment and can be found in the OMEMS drawer next to the scanner.

### **** Photos of old and new OMEMS pairs in drawer go here ****

### **** IMPORTANT NOTE ****

- If you have an on-going study in which you have already used OMEMS please continue using the OLD pair comprising device numbers 1001 (subject's left ear, black connector) and 1002 (subject's right ear, red connector).

- If you have a new study, in which you have not already started to use OMEMS, please use the NEW pair comprising device numbers 4001 (left, black connector) and 4002 (right, red connector).

### Equalisation filers

The OMEMS devices have a reasonably wide and consistent audio response which may be appropriate but where a more uniform audio response is required an equalisation procedure based on an individual device calibration has been provided. You should use the Matalb script "apply_filters.m" if you wish to apply these equalisation fiters to audio files to be played to subjects.

Equalisation filters for both the old and new OMEMS pairs are found in the "filters" subdirectory of the omems-filters repository. A filter appropriate to the OMEMS pair in use must be selected. When using apply_filter.m please select the filters according to the their device serial numbers.

The old OMEMS pair have serial numbers 1001 and 1002. The new pair have serial numbers 4001 and 4002. The equalisation files are named with the serial number of the left channel followed by the date and time at which it was calibrated and then the serial number of the right channel followed by its calibration date and time. So, for example, for the old OMEMS with Shure ear-tips select the equalisation file named "1001-20260324-131413---1002-20260324-131841---Shure.mat"). For the new OMEMS pair select a file starting 4001... (e.g. 4001-20251218-130141---4002-20251218-131207.mat).

A regular, weekly, quality assureance (QA) procedure will be carried out to verify that the audio response of the OMEMS devices, both old and new, remains consistent with it's calibration. The QA results are logged to the "filters.log" file in the omems-filters Github repository.

If the QA procedure determines the response differ by more than would be expected by repeat measurement and eartip positioning a new calibration will be performed and the newer equalisation files will become available.

If the QA procedure determines that a device has become faulty (e.g. a very different frequency response - worst case threshold 3 dB difference) the device will be repaired and re-calibrated with new equalisation file. Or a backup pair will be installed (e.g. S/N 4007...4008) in place of the faulty pair with appropriate equalisation filter file.

