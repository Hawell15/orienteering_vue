<template>
    <table class="table table-striped table-bordered table-hover">
        <thead class="table-primary">
            <tr>
                <th @click="orderTable('id')">ID</th>
                <th @click="orderTable('group_name')">Grupa</th>
                <th @click="orderTable('competition_name')">Competiția</th>
                <th @click="orderTable('date')">Data</th>
                <th @click="orderTable('rang')">Rang</th>
                <th @click="orderTable('clasa')">Clasa</th>
                <th @click="orderTable('ecn_coeficient')">ECN Coeficient</th>
                <th @click="orderTable('results_count')">Rezultate</th>
                <th colspan="3">Acțiuni</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="element in elements" :key="element.id">
                <td><a :href="`groups/${element.id}`">{{element.id}}</a></td>
                <td><a :href="`groups/${element.id}`">{{element.group_name}}</a></td>
                <td><a :href="`competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                <td>{{element.date}}</td>
                <td>{{element.rang}}</td>
                <td>{{element.clasa_name}}</td>
                <td>{{element.ecn_coeficient}}</td>
                <td><a :href="`results?group_id=${element.id}`">{{element.results_count}}</a></td>
                <td><a class="btn btn-sm btn-warning" :href="`groups/${element.id}`"> Arată </a></td>
                <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                <td><button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">Șterge</button></td>
            </tr>
        </tbody>
    </table>
    <Modal ref="modal" :group="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content')

const props = defineProps({
    elements: Object
})

const emit = defineEmits(['order'])

const modalElement = ref({})
const modal = ref(null)

function deleteElement(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/groups/${id}`).then(() => {
            props.elements = props.elements.filter(group => group.id !== id)
        })
    }
}

function editElement(element) {
    modalElement.value = { ...element }
    modal.value.show()
}

function updateElement(elementData, done) {
    axios.patch(`/groups/${elementData.id}.json`, { group: elementData }).then(res => {
        const index = props.elements.findIndex(c => c.id === res.data.id)
        if (index !== -1) props.elements[index] = { ...props.elements[index], ...res.data }
        done()
    })
}

function orderTable(sortKey) {
    emit('order', sortKey)
}
</script>
