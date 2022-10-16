only developed on linux.
require: `waifu2x-ncnn-vulkan`, `imagemagick`

todo:
~~auto assign denoise level based on jpg quality.~~
~~whenever saved metadata is modified, add "modified" flag.~~
~~add "modified" flag filter to remake during operation~~
~~remove "modified" flag each time operation is completed on an entry~~
manually edit denoise value
hide some more UI element



W 0:00:02.396   ~Thread: A Thread object has been destroyed without wait_to_finish() having been called on it. Please do so to ensure correct cleanup of the thread.



hmm alright, but what does it do exactly? If I put wait to finish I will have to wait and freeze until the thread is finished, doesn't that mean it's pointless to have separate thread in the first place?



E 0:00:02.397   wait_to_finish: A Thread can't wait for itself to finish.



Huh, but you are the one who told me to do it!! I follow the example on wiki. What seems to be the problem here?
