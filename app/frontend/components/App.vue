<template>
  <div class="vue-app">
  </div>
</template>

<script setup>
import { ref } from 'vue'
const count = ref(0)
</script>
<style>
.label-filter {
    width: 150px;
    display: inline-block;
    text-align: left;
    margin-bottom: 5px;
}

.custom-select,
.custom-input {
    word-wrap: normal;
    width: 140px;
    border-radius: 0.375rem;
    text-align: center;
    background-color: lightblue;
    border: 1px solid #ced4da;
}

.range-wrapper {
    display: inline-flex;
    align-items: center;
    gap: 8px;
}

.range-separator {
    font-weight: 600;
}
</style>
