<template>
    <Create ref="create" @save="saveResult" />
    <button class="btn btn-primary" @click="$refs.create.createNew()">Creaza Rezultat</button>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import Create from './Create.vue'
const create = ref(null)

onMounted(() => {
    create.value.createNew()
})

function saveResult() {
    window.location = "/results?sorting[direction]=desc";
}
</script>
