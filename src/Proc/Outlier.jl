module Outlier
export cubeAnomalies, simpleAnomalies
importall ..DAT
importall ..CubeAPI
importall ..Cubes
import ..Proc
using MultivariateAnomalies

function getDetectParameters(methodlist,trainarray,ntime)
  P = getParameters(methodlist,trainarray);
  init_detectAnomalies(zeros(Float64,ntime,size(trainarray,2)), P);
  P
end

"""
    cubeAnomalies(cube, methods, trainArray)

A simple wrapper around the function `detectAnomalies!` from the [MultivariateAnomalies](https://github.com/milanflach/MultivariateAnomalies.jl)
package.

* `cube` data cube with a axes: `TimeAxis`, `VariableAxis`
* `methods` vector of methods to be applied, choose from: `KDE`,`T2`,`REC`,`KNN-Gamma`,`KNN-Delta`,`SVDD`,`KNFST`
* `trainArray` a matrix of `nsample` x `nvar`, to estimate the training parameters for the model. Ideally does not contain any extreme values

**Input Axes** `TimeAxis`, `Variable`axis

**Output Axes** `TimeAxis`, `Method`axis
"""
function cubeAnomalies(c::AbstractCubeData,methods,trainArray)
  indims = InDims(TimeAxis,VariableAxis,miss=NaNMissing())
  outdims = OutDims(TimeAxis,CategoricalAxis("Method",methods),miss=NaNMissing())
  P = getDetectParameters(methods,trainArray,length(getAxis(TimeAxis,c)))
  mapCube(cubeAnomalies,c,P,indims=indims,outdims=outdims)
end

function cubeAnomalies(xout::AbstractArray, xin::AbstractArray, P::MultivariateAnomalies.PARAMS)
 detectAnomalies!(Float64.(xin), P)
 for i = 1:length(P.algorithms)
   copy!(view(xout, :, i), MultivariateAnomalies.return_scores(i, P))
 end
 return(xout)
end


function simpleAnomalies(c::AbstractCubeData,methods)
  indims = InDims(TimeAxis,VariableAxis,miss=NaNMissing()),
  outdims = OutDims(TimeAxis,CategoricalAxis("Method",methods),miss=NaNMissing())
  mapCube(simpleAnomalies,c,methods,indims=indims,outdims=outdims)
end

function simpleAnomalies(xout::AbstractArray, xin::AbstractArray,methods)
  if !any(isnan,xin)
    P=getParameters(methods,xin)
    res=detectAnomalies(xin,P)
    for i=1:length(res)
      xout[:,i]=res[i]
    end
  else
    xout[:]=NaN
    end
end

end
