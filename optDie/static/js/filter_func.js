function getMinMax(arr) {
    var len = arr.length;
    var max = Number(arr[0]);
    var min = Number(arr[0]);
    while (len--) {
        max = (Number(arr[len]) > max) ? Number(arr[len]) : max;
        min = (Number(arr[len]) < min) ? Number(arr[len]) : min;
    }
    return [min, max];
}