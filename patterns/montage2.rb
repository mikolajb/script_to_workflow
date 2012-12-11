dataRepository = GObj.create("fotos")
mProjectPP = GObj.create("mProjectPP")
mDiffFit = GObj.create("mDiffFit")
mConcatDiff = GObj.create("mConcatDiff")
mBgModel = GObj.create("mBgModel")
mBackground = GObj.create("mBackground")
mImgTbl = GObj.create("mImgTbl")
pipeline = GObj.create("pipeline")

data_handler = dataRepository.async_load_fotos("12345")
data = data_handler.get_result

fotos_result = nil
P.parallelFor(data) do |f|
# fotos.length.times do |i|
  fotos_handler = mProjectPP.async_do_sth(data)
  fotos_result = fotos_handler.get_result
end

diffFit_result = nil
P.parallelFor(fotos_result) do |f|
# (fotos.length + 2).times do |i|
  diffFit_handler = mDiffFit.async_do_sth(fotos_result)
  diffFit_result = diffFit_handler.get_result
end

concatDiff_handler = mConcatDiff.async_do_sth(diffFit_result)
concatDiff_result = concatDiff_handler.get_result

bgModel_handler = mBgModel.async_do_sth(concatDiff_result)
bgModel_result = bgModel_handler.get_result

backgrounds_result = nil
P.parallelFor(fotos_result) do |f|
# fotos.length.times do |i|
  backgrounds_handler = mBackground.async_do_sth(fotos_result, bgModel_result)
  backgrounds_result = backgrounds_handler.get_result
end

imgTbl_handler = mImgTbl.async_do_sth(backgrounds_result)
imgTbl_result = imgTbl_handler.get_result

pipeline_handler = pipeline.async_do_sth(imgTbl_result)
pipeline_result = pipeline_handler.get_result
